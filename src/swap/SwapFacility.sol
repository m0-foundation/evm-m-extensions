// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    AccessControlUpgradeable
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import { ReentrancyLock } from "../../lib/uniswap-v4-periphery/src/base/ReentrancyLock.sol";

import { IMTokenLike } from "../interfaces/IMTokenLike.sol";
import { IMExtension } from "../interfaces/IMExtension.sol";

import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { IV3SwapRouter } from "./interfaces/uniswap/IV3SwapRouter.sol";

abstract contract SwapFacilityStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.MEarnerManager
    struct SwapFacilityStorageStruct {
        mapping(address token => bool whitelisted) whitelistedTokens;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.SwapFacility")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _SWAP_FACILITY_STORAGE_LOCATION =
        0x2f6671d90ec6fb8a38d5fa4043e503b2789e716b6e5219d1b20da9c6434dde00;

    function _getSwapFacilityStorageLocation() internal pure returns (SwapFacilityStorageStruct storage $) {
        assembly {
            $.slot := _SWAP_FACILITY_STORAGE_LOCATION
        }
    }
}

/**
 * @title  Swap Facility
 * @notice A contract responsible for swapping between $M Extensions.
 * @author M0 Labs
 */
contract SwapFacility is ISwapFacility, AccessControlUpgradeable, SwapFacilityStorageLayout, ReentrancyLock {
    using SafeERC20 for IERC20;

    bytes32 public constant EARNERS_LIST_IGNORED_KEY = "earners_list_ignored";
    bytes32 public constant EARNERS_LIST_NAME = "earners";
    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable mToken;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable registrar;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable wrappedMToken;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable swapRouter;

    /// @notice Fee for Uniswap V3 swap router (0.01%)
    uint24 internal constant UNISWAP_V3_FEE = 100;

    /// @notice Path address size
    uint256 internal constant PATH_ADDR_SIZE = 20;

    /// @notice Path fee size
    uint256 internal constant PATH_FEE_SIZE = 3;

    /// @notice Path next offset
    uint256 internal constant PATH_NEXT_OFFSET = PATH_ADDR_SIZE + PATH_FEE_SIZE;

    /**
     * @notice Constructs SwapFacility Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_        The address of $M token.
     * @param  registrar_     The address of Registrar.
     * @param  wrappedMToken_ The address of base token.
     * @param  swapRouter_    The address of the Uniswap V3 swap router.
     */
    constructor(address mToken_, address registrar_, address wrappedMToken_, address swapRouter_) {
        _disableInitializers();

        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((registrar = registrar_) == address(0)) revert ZeroRegistrar();
        if ((wrappedMToken = wrappedMToken_) == address(0)) revert ZeroWrappedMToken();
        if ((swapRouter = swapRouter_) == address(0)) revert ZeroSwapRouter();
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes SwapFacility Proxy.
     * @param  admin Address of the SwapFacility admin.
     * @param  tokens The list of whitelisted tokens.
     */
    function initialize(address admin, address[] memory tokens) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        for (uint256 i; i < tokens.length; i++) {
            _whitelistToken(tokens[i], true);
        }
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc ISwapFacility
    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        _swap(extensionIn, extensionOut, amount, recipient);

        emit Swapped(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);

        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        _swap(extensionIn, extensionOut, amount, recipient);

        emit Swapped(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);

        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        _swap(extensionIn, extensionOut, amount, recipient);

        emit Swapped(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInM(address extensionOut, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionOut);

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionOut);

        try IMTokenLike(mToken).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionOut);

        try IMTokenLike(mToken).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutM(address extensionIn, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedSwapper(msg.sender);

        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedSwapper(msg.sender);

        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedSwapper(msg.sender);

        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInToken(
        address tokenIn,
        uint256 amountIn,
        address extensionOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external {
        _revertIfNotApprovedExtension(extensionOut);
        _revertIfNotWhitelistedToken(tokenIn);
        _revertIfZeroAmount(amountIn);
        _revertIfInvalidSwapInPath(tokenIn, path);
        _revertIfZeroRecipient(recipient);

        uint256 tokenInBalanceBefore = IERC20(tokenIn).balanceOf(address(this));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(swapRouter, amountIn);

        // Swap input token for base token in Uniswap pool
        uint256 amountOut;
        if (path.length == 0) {
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: wrappedMToken,
                fee: UNISWAP_V3_FEE,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

            amountOut = IV3SwapRouter(swapRouter).exactInputSingle(params);
        } else {
            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            });

            amountOut = IV3SwapRouter(swapRouter).exactInput(params);
        }

        // If extensionOut is Wrapped $M, transfer to the recipient directly
        if (extensionOut == wrappedMToken) {
            IERC20(wrappedMToken).transfer(recipient, amountOut);
        } else {
            // Otherwise, swap the Wrapped $M to extensionOut
            _swap(wrappedMToken, extensionOut, amountOut, recipient);
        }

        // NOTE: UniswapV3 router allows exactInput or exactInputSingle operations to not fully utilize
        //       the given input token amount if the pool does not have sufficient liquidity.
        //       Refund any remaining input token balance to the caller.
        uint256 remainingBalance = IERC20(tokenIn).balanceOf(address(this)) - tokenInBalanceBefore;
        if (remainingBalance > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, remainingBalance);
        }

        emit Swapped(tokenIn, extensionOut, amountOut, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutToken(
        address extensionIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotWhitelistedToken(tokenOut);
        _revertIfZeroAmount(amountIn);
        _revertIfInvalidSwapOutPath(tokenOut, path);
        _revertIfZeroRecipient(recipient);

        uint256 extensionInBalanceBefore = IERC20(extensionIn).balanceOf(address(this));
        IERC20(extensionIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Swap the extensionIn to Wrapped $M token
        if (extensionIn != wrappedMToken) {
            uint256 balanceBefore = IERC20(wrappedMToken).balanceOf(address(this));

            _swap(extensionIn, wrappedMToken, amountIn, address(this));

            // Calculate amountIn as the difference in balance to account for rounding errors
            amountIn = IERC20(wrappedMToken).balanceOf(address(this)) - balanceBefore;
        }

        // Approve Swap Router to spend wrappedMToken (Wrapped $M)
        IERC20(wrappedMToken).approve(swapRouter, amountIn);

        // Swap wrappedMToken in Uniswap pool for output token
        uint256 amountOut;
        if (path.length == 0) {
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: wrappedMToken,
                tokenOut: tokenOut,
                fee: UNISWAP_V3_FEE,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

            amountOut = IV3SwapRouter(swapRouter).exactInputSingle(params);
        } else {
            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
                path: path,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            });

            amountOut = IV3SwapRouter(swapRouter).exactInput(params);
        }

        // NOTE: UniswapV3 router allows exactInput or exactInputSingle operations to not fully utilize
        //       the given input token amount if the pool does not have sufficient liquidity.
        //       Refund any remaining input token balance to the caller.
        uint256 remainingBalance = IERC20(extensionIn).balanceOf(address(this)) - extensionInBalanceBefore;
        if (remainingBalance > 0) {
            IERC20(extensionIn).transfer(msg.sender, remainingBalance);
        }

        emit Swapped(extensionIn, tokenOut, amountOut, recipient);
    }

    /// @inheritdoc ISwapFacility
    function whitelistToken(address token, bool isWhitelisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistToken(token, isWhitelisted);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc ISwapFacility
    function msgSender() public view returns (address) {
        return _getLocker();
    }

    /// @inheritdoc ISwapFacility
    function whitelistedTokens(address token) public view returns (bool isWhitelisted) {
        return _getSwapFacilityStorageLocation().whitelistedTokens[token];
    }

    /* ============ Private Interactive Functions ============ */
    /**
     * @notice Swaps one $M Extension to another.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function _swap(address extensionIn, address extensionOut, uint256 amount, address recipient) private {
        uint256 balanceBefore = _mBalanceOf(address(this));

        // Recipient parameter is ignored in the MExtension, keeping it for backward compatibility.
        IMExtension(extensionIn).unwrap(address(this), amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for rounding errors.
        amount = _mBalanceOf(address(this)) - balanceBefore;

        IERC20(mToken).approve(extensionOut, amount);
        IMExtension(extensionOut).wrap(recipient, amount);
    }

    /**
     * @notice Swaps $M token to $M Extension.
     * @param  extensionOut The address of the M Extension to swap to.
     * @param  amount       The amount of $M token to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function _swapInM(address extensionOut, uint256 amount, address recipient) private {
        IERC20(mToken).transferFrom(msg.sender, address(this), amount);
        IERC20(mToken).approve(extensionOut, amount);
        IMExtension(extensionOut).wrap(recipient, amount);

        emit SwappedInM(extensionOut, amount, recipient);
    }

    /**
     * @notice Swaps $M Extension to $M token.
     * @param  extensionIn The address of the $M Extension to swap from.
     * @param  amount      The amount of $M Extension tokens to swap.
     * @param  recipient   The address to receive $M tokens.
     */
    function _swapOutM(address extensionIn, uint256 amount, address recipient) private {
        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        uint256 balanceBefore = _mBalanceOf(address(this));

        // Recipient parameter is ignored in the MExtension, keeping it for backward compatibility.
        IMExtension(extensionIn).unwrap(address(this), amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for rounding errors.
        amount = _mBalanceOf(address(this)) - balanceBefore;
        IERC20(mToken).transfer(recipient, amount);

        emit SwappedOutM(extensionIn, amount, recipient);
    }

    function _whitelistToken(address token, bool isWhitelisted) private {
        if (token == address(0)) revert ZeroToken();
        _getSwapFacilityStorageLocation().whitelistedTokens[token] = isWhitelisted;

        emit TokenWhitelisted(token, isWhitelisted);
    }

    /**
     * @notice Decode input and output tokens
     * @param  path Swap path
     * @return tokenInput Address of the input token
     * @return tokenOutput Address if the output token
     */
    function _decodeInputAndOutputTokens(
        bytes calldata path
    ) internal pure returns (address tokenInput, address tokenOutput) {
        // Validate path format
        if (
            (path.length < PATH_ADDR_SIZE + PATH_FEE_SIZE + PATH_ADDR_SIZE) ||
            ((path.length - PATH_ADDR_SIZE) % PATH_NEXT_OFFSET != 0)
        ) {
            revert InvalidPathFormat();
        }

        tokenInput = address(bytes20(path[:PATH_ADDR_SIZE]));

        // Calculate position of output token
        uint256 numHops = (path.length - PATH_ADDR_SIZE) / PATH_NEXT_OFFSET;
        uint256 outputTokenIndex = numHops * PATH_NEXT_OFFSET;

        tokenOutput = address(bytes20(path[outputTokenIndex:outputTokenIndex + PATH_ADDR_SIZE]));
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken).balanceOf(account);
    }

    /**
     * @dev    Checks if the given extension is an approved earner.
     * @param  extension Address of the extension to check.
     * @return True if the extension is an approved earner, false otherwise.
     */
    function _isApprovedEarner(address extension) private view returns (bool) {
        return
            IRegistrarLike(registrar).get(EARNERS_LIST_IGNORED_KEY) != bytes32(0) ||
            IRegistrarLike(registrar).listContains(EARNERS_LIST_NAME, extension);
    }

    /**
     * @dev   Reverts if `extension` is not an approved earner.
     * @param extension Address of an extension.
     */
    function _revertIfNotApprovedExtension(address extension) internal view {
        if (!_isApprovedEarner(extension)) revert NotApprovedExtension(extension);
    }

    /**
     * @dev   Reverts if `account` is not an approved M token swapper.
     * @param account Address of an extension.
     */
    function _revertIfNotApprovedSwapper(address account) internal view {
        if (!hasRole(M_SWAPPER_ROLE, account)) revert NotApprovedSwapper(account);
    }

    /**
     * @dev   Reverts if not whitelisted token.
     * @param token Address of a token.
     */
    function _revertIfNotWhitelistedToken(address token) internal view {
        if (token != wrappedMToken && !whitelistedTokens(token)) revert NotWhitelistedToken(token);
    }

    /**
     * @dev   Reverts if `recipient` is address(0).
     * @param recipient Address of a recipient.
     */
    function _revertIfZeroRecipient(address recipient) internal pure {
        if (recipient == address(0)) revert ZeroRecipient();
    }

    /**
     * @dev   Reverts if `amount` is equal to 0.
     * @param amount Amount of token.
     */
    function _revertIfZeroAmount(uint256 amount) internal pure {
        if (amount == 0) revert ZeroAmount();
    }

    /**
     * @notice Reverts if the swap path is invalid for swapping in.
     * @param  tokenInput Address of the input token.
     * @param  path Swap path.
     */
    function _revertIfInvalidSwapInPath(address tokenInput, bytes calldata path) internal view {
        if (path.length != 0) {
            (address tokenInput_, address tokenOutput) = _decodeInputAndOutputTokens(path);
            if (tokenInput_ != tokenInput || tokenOutput != wrappedMToken) revert InvalidPath();
        }
    }

    /**
     * @notice Reverts if the swap path is invalid for swapping out.
     * @param  tokenOutput Address of the output token.
     * @param  path Swap path.
     */
    function _revertIfInvalidSwapOutPath(address tokenOutput, bytes calldata path) internal view {
        if (path.length != 0) {
            (address tokenInput, address tokenOutput_) = _decodeInputAndOutputTokens(path);
            if (tokenInput != wrappedMToken || tokenOutput_ != tokenOutput) revert InvalidPath();
        }
    }
}
