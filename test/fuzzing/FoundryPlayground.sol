// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FuzzGuided.sol";

contract FoundryPlayground is FuzzGuided {
    function setUp() public {
        vm.warp(1524785992); //echidna starting time
        fuzzSetup();
    }

    function test_basic() public {
        assert(false);
    }

    function test_coverage_mint() public {
        fuzz_mint(1e6);
        setActor(USER2);
        fuzz_warpWeeks(1);
        setActor(USER2);
        fuzz_swapInM(1e6);
        fuzz_warpDays(1);
        setActor(USER2);
        fuzz_swapOutM(1e6);
    }

    function test_swapInToken() public {
        fuzz_swapInToken(1e6);
    }

    function test_setFeeRecipient_MYieldFee() public {
        fuzz_setFeeRecipient_MYieldFee(0);
    }

    function test_setClaimRecipient_MYieldFee() public {
        fuzz_setClaimRecipient_MYieldFee(1243842114999043724632953757827977672887);
    }

    function test_swapOutToken_MEarnerManager() public {
        fuzz_transferFrom_MYieldFee(0);
        fuzz_transferFrom_MYieldFee(3627267021883914267372266916118009144674103721966203995273361491607);
        fuzz_approve_MYieldFee(17746552764780105160738418812046093807414944557038597050867616710064);
        fuzz_approve_MEarnerManager(72511897545339256365686171027320470996271315535875310140166);
        fuzz_setFeeRecipient_MEarnerManager(143763691406449532991508316138316936871138116615149875197084);
        fuzz_transfer_MYieldFee(0);
        fuzz_swapInM(2273847);
        fuzz_swapOutToken(38823);
    }

    function test_swapInToken_MEarnerManager() public {
        fuzz_swapInToken(1);
    }

    function test_repro_ERR() public {
        vm.warp(block.timestamp + 390247);
        vm.roll(block.number + 475);
        try
            this.fuzz_setFeeRecipient_MYieldFee(
                47320730170102804077797434384377464548113352208291319152386305098695213677421
            )
        {} catch {}

        try this.fuzz_unwrap_MYieldFee(1153748009) {} catch {}

        vm.warp(block.timestamp + 328);
        vm.roll(block.number + 255);
        try this.fuzz_disableEarning_MYieldFee(47879553443103502050130818603502199422197335089211511) {} catch {}

        vm.warp(block.timestamp + 521319);
        vm.roll(block.number + 58783);
        try this.YIELD_RECIPIENT_MANAGER_ROLE() {} catch {}

        try this.YIELD_RECIPIENT_MANAGER_ROLE() {} catch {}

        try
            this.fuzz_disableEarning_MYieldFee(
                32838990291181780723315880678821250561631979174516767409550631434434743359753
            )
        {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        vm.warp(block.timestamp + 139332);
        vm.roll(block.number + 10000);
        try this.liquidityTokenId() {} catch {}

        vm.warp(block.timestamp + 344203);
        vm.roll(block.number + 7494);
        try
            this.fuzz_unwrap_MEarnerManager(
                23432317188101754195305058017349657498089222992525263944440584055062707855844
            )
        {} catch {}

        try
            this.fuzz_wrap_MEarnerManager(43539690873773209113412005160474671656462550208699309721395099769989806750007)
        {} catch {}

        vm.warp(block.timestamp + 78683);
        vm.roll(block.number + 53349);

        try this.fuzz_wrap_MYieldFee(4370001) {} catch {}

        vm.warp(block.timestamp + 349486);
        vm.roll(block.number + 32737);
        try
            this.fuzz_claimYield_MYieldToOne(
                5123145967379927349793506794141694767798354165875026803650902639453913792480
            )
        {} catch {}

        vm.warp(block.timestamp + 519847);
        vm.roll(block.number + 9920);
        try this.M_SWAPPER_ROLE() {} catch {}

        vm.warp(block.timestamp + 414579);
        vm.roll(block.number + 4428);
        try
            this.fuzz_setFeeRecipient_MYieldFee(
                2634818944773847744198244903790044394598908747025426236436553555225480967634
            )
        {} catch {}

        vm.warp(block.timestamp + 33605);
        vm.roll(block.number + 23978);
        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        try this.EXP_SCALED_ONE() {} catch {}

        try this.EARNERS_LIST() {} catch {}

        try this.fuzz_unwrap_MYieldToOne(4370001) {} catch {}

        vm.warp(block.timestamp + 599608);
        vm.roll(block.number + 33357);
        try this.EARNER_MANAGER_ROLE() {} catch {}

        vm.warp(block.timestamp + 1000);
        vm.roll(block.number + 1984);
        try this.fuzz_transferFrom_MYieldFee(9128977902197200) {} catch {}

        vm.warp(block.timestamp + 110855);
        vm.roll(block.number + 60054);
        try this.fuzz_wrap_MEarnerManager(477) {} catch {}

        vm.warp(block.timestamp + 13054);
        vm.roll(block.number + 33357);

        try this.YIELD_FEE_RATE() {} catch {}

        vm.warp(block.timestamp + 547623);
        vm.roll(block.number + 53166);
        try this.fuzz_unwrap_MEarnerManager(623) {} catch {}

        vm.warp(block.timestamp + 420078);
        vm.roll(block.number + 9242);
        try this.fuzz_transferFrom_MYieldFee(4369999) {} catch {}

        vm.warp(block.timestamp + 65535);
        vm.roll(block.number + 20243);
        try this.fuzz_disableEarning_MEarnerManager(1626874835) {} catch {}

        try this.ONE_HUNDRED_PERCENT() {} catch {}

        vm.warp(block.timestamp + 33605);
        vm.roll(block.number + 30011);
        try this.fuzz_wrap_MYieldToOne(149) {} catch {}

        try this.fuzz_setAccountInfo_MEarnerManager(3614545, address(0x0), false) {} catch {}

        vm.warp(block.timestamp + 438667);
        vm.roll(block.number + 4223);
        try this.ONE_HUNDRED_PERCENT() {} catch {}

        vm.warp(block.timestamp + 463587);
        vm.roll(block.number + 49415);
        try
            this.fuzz_claimFee_MYieldFee(36204095692582969784035200233856632529702542816227508631571658829057496363005)
        {} catch {}

        vm.warp(block.timestamp + 450);
        vm.roll(block.number + 703);
        try
            this.fuzz_approve_MYieldToOne(98241975931135459926127606311371839067201019395956044556887408041851222459156)
        {} catch {}

        try
            this.fuzz_swapOutToken(15200776214347954908314247897698906055478621111480601187822470504394581216873)
        {} catch {}

        vm.warp(block.timestamp + 161069);
        vm.roll(block.number + 31232);
        try
            this.fuzz_approve_MEarnerManager(
                231779576679727383229304315451467484605836067158701160775140757827312571858
            )
        {} catch {}

        try this.fuzz_swapInToken(66122707011742) {} catch {}

        vm.warp(block.timestamp + 273333);
        vm.roll(block.number + 60054);

        try this.liquidityTokenId() {} catch {}

        try
            this.fuzz_claimFor_MEarnerManager(
                23365453498122712034363206871923900364550710487792137532419322263066651047676
            )
        {} catch {}

        vm.warp(block.timestamp + 32767);
        vm.roll(block.number + 23653);
        try this.M_EARNER_RATE() {} catch {}

        try
            this.fuzz_swapInToken(710745371466665168754939446127485406422388467640155919531614106365050485002)
        {} catch {}

        try this.UNISWAP_V3_FEE() {} catch {}

        vm.warp(block.timestamp + 547623);
        vm.roll(block.number + 5023);
        try this.M_SWAPPER_ROLE() {} catch {}

        try
            this.fuzz_setFeeRecipient_MYieldFee(
                2524036888902800813553701312887929088290324124933662533790621247965019043534
            )
        {} catch {}

        vm.warp(block.timestamp + 554465);
        vm.roll(block.number + 58783);
        try this.M_SWAPPER_ROLE() {} catch {}

        try
            this.fuzz_setFeeRecipient_MEarnerManager(
                871789033740168404484474203862827555583776990768355710286652525446080392165
            )
        {} catch {}

        vm.warp(block.timestamp + 447588);
        vm.roll(block.number + 16089);
        try
            this.fuzz_transfer_MYieldToOne(
                93996948004593177624110328634372588259893890562990257475452489156712186929763
            )
        {} catch {}

        vm.warp(block.timestamp + 337455);
        vm.roll(block.number + 23403);
        try this.fuzz_swapInM(484225) {} catch {}

        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 24311);
        try this.M_SWAPPER_ROLE() {} catch {}

        vm.warp(block.timestamp + 172101);
        vm.roll(block.number + 23403);
        try this.fuzz_approve_MYieldFee(1238592) {} catch {}

        try this.EXP_SCALED_ONE() {} catch {}

        try
            this.fuzz_enableEarning_MYieldToOne(
                53826161282890148475845523375081912402180289008320125536321740536773496393661
            )
        {} catch {}

        vm.warp(block.timestamp + 419861);
        vm.roll(block.number + 22699);
        try this.fuzz_swapOutM(47) {} catch {}

        vm.warp(block.timestamp + 487078);
        vm.roll(block.number + 6721);
        try
            this.fuzz_approve_MYieldToOne(1528834653060979551045810549793494062172478767649375560831588850369200078342)
        {} catch {}

        vm.warp(block.timestamp + 45142);
        vm.roll(block.number + 45405);
        try
            this.fuzz_claimYield_MYieldToOne(
                12608663692834392827342676739680120928187989444709059133586844489893482462333
            )
        {} catch {}

        vm.warp(block.timestamp + 519847);
        vm.roll(block.number + 12338);
        try this.fuzz_wrap_MYieldFee(1524785993) {} catch {}

        vm.warp(block.timestamp + 156190);
        vm.roll(block.number + 34272);
        try
            this.fuzz_setAccountInfo_MEarnerManager(2326194029273014991154538124714799718952, address(0x20000), true)
        {} catch {}

        vm.warp(block.timestamp + 360624);
        vm.roll(block.number + 53451);
        try this.EARNERS_LIST() {} catch {}

        vm.warp(block.timestamp + 69251);
        vm.roll(block.number + 58783);
        try this.fuzz_enableEarning_MYieldToOne(3577147) {} catch {}

        try this.fuzz_swapOutM(755) {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        vm.warp(block.timestamp + 209930);
        vm.roll(block.number + 127);
        try
            this.fuzz_setFeeRecipient_MEarnerManager(
                47624920369267344636061836293698954185080138241416929624608702187628429549580
            )
        {} catch {}

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 30011);
        try this.fuzz_transfer_MEarnerManager(1524785992) {} catch {}

        vm.warp(block.timestamp + 183145);
        vm.roll(block.number + 53011);
        try
            this.fuzz_disableEarning_MYieldFee(
                52104468650214434208501441450978149466589128132818940088707576651058085070545
            )
        {} catch {}

        vm.warp(block.timestamp + 227131);
        vm.roll(block.number + 8166);
        try
            this.fuzz_claimFee_MYieldFee(97586615503428944861745746430386132070224820596801747444207172779739635764652)
        {} catch {}

        vm.warp(block.timestamp + 385348);
        vm.roll(block.number + 5952);
        try
            this.fuzz_approve_MEarnerManager(
                276259680912815824841786413823334451036914964943912613030085125108961872972
            )
        {} catch {}

        vm.warp(block.timestamp + 482712);
        vm.roll(block.number + 60364);
        try this.FEE_MANAGER_ROLE() {} catch {}

        vm.warp(block.timestamp + 440097);
        vm.roll(block.number + 59552);
        try
            this.fuzz_wrap_MYieldToOne(5630558099940961079798989636859804497764537271292569473212534919347458212620)
        {} catch {}

        vm.warp(block.timestamp + 379552);
        vm.roll(block.number + 45852);
        try
            this.fuzz_enableEarning_MYieldFee(
                4445090124924288490550023816360372714054680577792970385383213872416507853844
            )
        {} catch {}

        try this.fuzz_claimYieldFor_MYieldFee(1524785992) {} catch {}

        try this.fuzz_transferFrom_MEarnerManager(1) {} catch {}

        vm.warp(block.timestamp + 448552);
        vm.roll(block.number + 23885);
        try this.DEFAULT_ADMIN_ROLE() {} catch {}

        try
            this.fuzz_setAccountInfo_MEarnerManager(
                22618209749787945400905169599416801574158967733994457566183794530012922555088,
                address(0xffffffff),
                false
            )
        {} catch {}

        vm.warp(block.timestamp + 136394);
        vm.roll(block.number + 34272);
        try this.DEFAULT_ADMIN_ROLE() {} catch {}

        fuzz_swapInToken(4370001);
    }

    function test_repro_ERR2() public {
        try
            this.fuzz_setFeeRecipient_MYieldFee(
                47320730170102804077797434384377464548113352208291319152386305098695213677421
            )
        {} catch {}

        try this.fuzz_unwrap_MYieldFee(1524785993) {} catch {}

        try this.fuzz_disableEarning_MYieldFee(47879553443103502050130818603502199422197335089211511) {} catch {}

        try this.YIELD_RECIPIENT_MANAGER_ROLE() {} catch {}

        try this.YIELD_RECIPIENT_MANAGER_ROLE() {} catch {}

        try
            this.fuzz_disableEarning_MYieldFee(
                32838990291181780723315880678821250561631979174516767409550631434434743359753
            )
        {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        try this.liquidityTokenId() {} catch {}

        try
            this.fuzz_unwrap_MEarnerManager(
                56832694852436328738413837008933948460434280247947471844600405115220788039295
            )
        {} catch {}

        try
            this.fuzz_wrap_MEarnerManager(43539690873773209113412005160474671656462550208699309721395099769989806750007)
        {} catch {}

        try this.fuzz_enableEarning_MYieldToOne(4370001) {} catch {}

        try this.fuzz_wrap_MYieldFee(4370001) {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        try
            this.fuzz_claimYield_MYieldToOne(
                5123145967379927349793506794141694767798354165875026803650902639453913792480
            )
        {} catch {}

        try this.M_SWAPPER_ROLE() {} catch {}

        try
            this.fuzz_setFeeRecipient_MYieldFee(
                9966899602248768460594085587709877547221736899496210671415471839211668548596
            )
        {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        try this.EXP_SCALED_ONE() {} catch {}

        try this.EARNERS_LIST() {} catch {}

        try this.fuzz_unwrap_MYieldToOne(4370001) {} catch {}

        try this.EARNER_MANAGER_ROLE() {} catch {}

        try this.fuzz_transferFrom_MYieldFee(10069466788306441) {} catch {}

        try this.fuzz_wrap_MEarnerManager(477) {} catch {}

        try
            this.fuzz_wrap_MEarnerManager(98028605881684357728216669948853501847660298233778072676867381703990179622222)
        {} catch {}

        try this.YIELD_FEE_RATE() {} catch {}

        try this.fuzz_unwrap_MEarnerManager(973) {} catch {}

        try this.fuzz_transferFrom_MYieldFee(4369999) {} catch {}

        try this.fuzz_disableEarning_MEarnerManager(1921939135) {} catch {}

        try this.ONE_HUNDRED_PERCENT() {} catch {}

        try this.fuzz_wrap_MYieldToOne(193) {} catch {}

        try this.fuzz_setAccountInfo_MEarnerManager(4369999, address(0x2fffffffd), false) {} catch {}

        try this.ONE_HUNDRED_PERCENT() {} catch {}

        try
            this.fuzz_claimFee_MYieldFee(97586615503428944861745746430386132070224820596801747444207172779739635764652)
        {} catch {}

        try
            this.fuzz_approve_MYieldToOne(98241975931135459926127606311371839067201019395956044556887408041851222459156)
        {} catch {}

        try
            this.fuzz_swapOutToken(115792089237316195423570985008687907853269984665640564039457584007913129639935)
        {} catch {}

        try
            this.fuzz_approve_MEarnerManager(
                473558184363444534656163518911057660449451622909370578455700205156256275549
            )
        {} catch {}

        try this.fuzz_swapInToken(66122707011742) {} catch {}

        try
            this.fuzz_setClaimRecipient_MYieldFee(
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            )
        {} catch {}

        try this.liquidityTokenId() {} catch {}

        try
            this.fuzz_claimFor_MEarnerManager(
                23365453498122712034363206871923900364550710487792137532419322263066651047676
            )
        {} catch {}

        try this.M_EARNER_RATE() {} catch {}

        try
            this.fuzz_enableEarning_MEarnerManager(
                67331580605746876298418714003759859786563645883739990485071866469450111243506
            )
        {} catch {}

        try
            this.fuzz_setFeeRate_MYieldFee(
                15158636383698468916173050564304561608705428844132100728596590562059253405866
            )
        {} catch {}

        try this.fuzz_transfer_MYieldFee(4370000) {} catch {}

        try this.fuzz_approve_MYieldFee(4370000) {} catch {}

        try
            this.fuzz_setClaimRecipient_MYieldFee(
                70935337494238705579906507889256094211239626909201709788861384019056686718327
            )
        {} catch {}

        try
            this.fuzz_setFeeRecipient_MEarnerManager(
                36737774747086134976187614681902021286326738957497747390745573168948214959936
            )
        {} catch {}

        try
            this.fuzz_transferFrom_MYieldToOne(
                35185863989612213877001009117029754095110761451467092767819194194258743207291
            )
        {} catch {}

        try
            this.fuzz_unwrap_MEarnerManager(
                29631076736684246826083535569574823064201569257951137436945855206424889175386
            )
        {} catch {}

        try this.YIELD_FEE_RATE() {} catch {}

        try this.fuzz_claimYieldFor_MYieldFee(4369999) {} catch {}

        try this.fuzz_swapOutToken(4369999) {} catch {}

        try this.fuzz_swapOutToken(4370000) {} catch {}

        try this.EARNERS_LIST() {} catch {}

        try this.EARNERS_LIST() {} catch {}

        try this.fuzz_unwrap_MYieldToOne(1625498574) {} catch {}

        try this.YIELD_FEE_RATE() {} catch {}

        try this.fuzz_setFeeRecipient_MEarnerManager(1524785993) {} catch {}

        try this.M_SWAPPER_ROLE() {} catch {}

        try this.fuzz_claimFee_MYieldFee(4369999) {} catch {}

        try
            this.fuzz_disableEarning_MEarnerManager(
                79726357789432714653249533937845864032440090542249797494466569555066761581344
            )
        {} catch {}

        try this.fuzz_unwrap_MYieldToOne(4369999) {} catch {}

        try this.fuzz_claimFor_MEarnerManager(4370000) {} catch {}

        try this.fuzz_enableEarning_MEarnerManager(1524785993) {} catch {}

        try
            this.fuzz_claimYield_MYieldToOne(
                38443545917045282082861810604559288502717171609111488398325854679603231937919
            )
        {} catch {}

        try this.fuzz_swap(4369999) {} catch {}

        try this.EARNERS_LIST() {} catch {}

        try this.fuzz_claimFee_MYieldFee(0) {} catch {}

        try this.liquidityTokenId() {} catch {}

        try this.EXP_SCALED_ONE() {} catch {}

        try
            this.fuzz_transferFrom_MYieldFee(
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            )
        {} catch {}

        try
            this.fuzz_approve_MEarnerManager(
                96048934405434941153903571106449461692153118475755332504681171615527810708201
            )
        {} catch {}

        try this.fuzz_updateIndex_MYieldFee(960200499400320458282284162812726317001514258479) {} catch {}

        try this.fuzz_approve_MEarnerManager(1) {} catch {}

        try
            this.fuzz_swapOutM(18517398406099063873812512456356315052412119092876204995719380302360777001877)
        {} catch {}

        try
            this.fuzz_setClaimRecipient_MYieldFee(167010847998198786965079122802400809208692275031224915168974766264743)
        {} catch {}

        try this.fuzz_swapOutToken(1) {} catch {}

        try this.fuzz_claimFee_MYieldFee(0) {} catch {}

        try this.BLACKLIST_MANAGER_ROLE() {} catch {}

        try
            this.fuzz_transfer_MYieldToOne(
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            )
        {} catch {}

        try
            this.fuzz_wrap_MYieldFee(31169852300737967449900209895133499443401657169510031357081038849252429997958)
        {} catch {}

        try this.fuzz_unwrap_MYieldToOne(247257451563867683691084044499630780) {} catch {}

        try
            this.fuzz_transferFrom_MEarnerManager(
                110923831327627468114588937201189470744323803490094133463329784511340205805535
            )
        {} catch {}

        fuzz_swapInToken(489);
    }
}
