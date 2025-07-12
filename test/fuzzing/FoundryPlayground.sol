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
        fuzz_randomizeConfigs(1, 0, 0, 0, 0, 0); //1 for default config
        fuzz_mint(2e6);
        setActor(USER2);
        fuzz_warpWeeks(1);
        setActor(USER2);
        fuzz_swapInM(1e6);
        fuzz_warpDays(1);
        setActor(USER2);
        fuzz_swapOutM(1e6);
    }

    function test_coverage_SwapInToken() public {
        fuzz_mint(2e6);
        setActor(USER2);
        fuzz_warpWeeks(1);
        setActor(USER2);
        fuzz_swapInToken(1e6);
        setActor(USER2);
        fuzz_swapOutToken(1e6);
    }

    function test_coverage_swapInToken() public {
        fuzz_swapInToken(1e6);
    }

    function test_coverage_allLiquiditySwaps() public {
        setActor(USER2);
        fuzz_allLiquidityUni(1e6, 1e6, 0, 1, 1);
        setActor(USER2);
        fuzz_swapZeroToOne(1e6);
        setActor(USER2);
        fuzz_swapOneToZero(1e6);
    }

    //696 wei diff
    function test_repro_MYF_02_01() public {
        fuzz_randomizeConfigs(
            1,
            3531501269871057330480477762512317360590737170023638838882653578921318550,
            8738991855125593005696616203935380219576422863227710228581398787039825252,
            121206369707769632886350105251,
            1105,
            84896196756360711667673848097991896142252907096609311681565561525332913
        );
        fuzz_mint(0);
        fuzz_swapInToken(4078868152336378008090050440221702487879015075493307743052115081178091601);
        fuzz_warpWeeks(296728850958886128174596513823391020707863688085807041606311181234092195);
        fuzz_updateIndex_MYieldFee(0);
        fuzz_setFeeRate_MYieldFee(0);
        fuzz_setFeeRecipient_MYieldFee(2385);
        vm.warp(block.timestamp + 4);
        vm.roll(block.number + 1);
        fuzz_setFeeRate_MYieldFee(84339188778250192053393094097997937594893378026398072272151961);
    }

    //239 wei diff
    function test_repro_MYF_02_02() public {
        fuzz_randomizeConfigs(
            64328701894630637431283885808928841890625919625630118301288,
            1477799979231960411239300943595099441264404253608819659784703772399,
            0,
            848600144863688483506631418384221899883777794645531215318647,
            0,
            0
        );
        fuzz_mint(0);
        fuzz_setFeeRate_MYieldFee(0);
        fuzz_warpWeeks(5137757999627636349167624565571586708270450651116721744822);
        fuzz_updateIndex_MYieldFee(147);
        fuzz_swapInToken(32947242190139113018588598329290106697324352456562824602595067842658109527);
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        fuzz_transferFrom_MYieldFee(4250067599402819121416816279145344529687550964723866);
    }

    //empty revert
    function test_repro_ERR_05() public {
        fuzz_randomizeConfigs(
            214,
            0,
            46139851530136299821104842957382193093817762380570921117282,
            314308239068957744316647356466113707464008065684269011914,
            0,
            5699734427460219275805289678589792098012968748602344399106635829
        );
        fuzz_transferFrom_MEarnerManager(1157557441910141324905215018018224914169949006124364387748);
        fuzz_swapInM(357);
        fuzz_wrap_MYieldToOne(112519122023066331369637067621283068853023177427705228620944);
        fuzz_claimFor_MEarnerManager(0);
        fuzz_approve_MEarnerManager(6313932184356262734732150030564970445172546024410150);
        fuzz_approve_MYieldToOne(34966636763148461498061123506164691571770183508375626929);
        fuzz_setFeeRate_MYieldFee(0);
        fuzz_unwrap_MYieldFee(17238370822720362770923335465179892242824249651730147356740);
        fuzz_swapInToken(0);
        fuzz_claimYieldFor_MYieldFee(0);
        fuzz_setFeeRecipient_MEarnerManager(0);
        fuzz_swapOutM(239508740197428772753125517607262116608997363572270);
        fuzz_transferFrom_MYieldFee(503157157443067693306812187332980908600862787650858);
        fuzz_approve_MYieldFee(89650225098794334306968545749099670967737160);
        fuzz_swapInM(12858633147676179606219013877472126945043000376157292);
        fuzz_unwrap_MEarnerManager(0);
        fuzz_transferFrom_MYieldToOne(0);
        fuzz_swapOutToken(276);
    }

    function test_repro_SWAP_01_01() public {
        fuzz_randomizeConfigs(
            16889982,
            17,
            5135712976829093906714751586228984909652221499046955234609293173426,
            1885464081798406194406093808409621094022553010545021677056038872593585,
            602,
            208788563053346195690184550654170768619812790219093969630516114340936476
        );
        fuzz_wrap_MYieldToOne(1435806453141873707353109937312094802261543082180546311247880316529884);
        fuzz_claimFor_MEarnerManager(0);
        fuzz_approve_MEarnerManager(1444104708871071380759731938026658565090585885859654271389124727779150140);
        fuzz_approve_MYieldToOne(70781279844310365134270049383027054761492082023683192992915202027442);
        fuzz_setFeeRate_MYieldFee(18);
        fuzz_unwrap_MYieldFee(436217437293928803189570493977897400847686566226280298144747573364020);
        fuzz_swapInToken(0);
        fuzz_setFeeRecipient_MEarnerManager(0);
        fuzz_transferFrom_MYieldFee(7794570933629331364239825628018257313863613235891206769570478466);
        fuzz_approve_MYieldFee(223006492224911575021572134845016533929530898393289670748683532697812528);
        fuzz_unwrap_MEarnerManager(0);
        fuzz_transferFrom_MYieldToOne(0);
        fuzz_swapInToken(87931809805384849450436888619741364982333737947665155336059015680070348990886);
        fuzz_claimFor_MEarnerManager(0);
        fuzz_setYieldRecipient_MYieldToOne(10290207330412922900630497077039110685590450581207222354671059894340);
        fuzz_approve_MYieldToOne(3178);
        fuzz_wrap_MYieldFee(5805555141084068736118080556377450849038535152556052143581106876850334);
        fuzz_mint(326);
        fuzz_setFeeRecipient_MEarnerManager(0);
        fuzz_mint(0);
        fuzz_transfer_MYieldFee(274337193405203412239645247591855087812999593732771367888345271144722455);
        fuzz_updateIndex_MYieldFee(103520995092677296904761193009355058809249459009690344349026359916494699);
        fuzz_transferFrom_MYieldToOne(570732959574702872425009437491501210405336825868063981133150324727061);
        fuzz_unwrap_MYieldFee(676715584872707230499184631066522480483040450080326972742348659);
        fuzz_swapOutToken(0);
        fuzz_approve_MEarnerManager(0);
        fuzz_unwrap_MYieldFee(1133895458298441221529213351095725193078419059030231603932355);
        fuzz_unwrap_MYieldToOne(6585685458379937842485079661450915963887271151236633640331165141047);
        fuzz_swapInM(16813169870453600717030958688739576033474993308517418588203931539844);
        fuzz_claimFor_MEarnerManager(56297868697416768162444499844834294120246972801157556229915646367317);
        fuzz_setFeeRecipient_MEarnerManager(0);
        fuzz_swapOutToken(82344110991946060678805380985876333552179925932371071359310843539724);
        vm.warp(block.timestamp + 52);
        vm.roll(block.number + 22408);
        fuzz_claimYieldFor_MYieldFee(0);
        fuzz_setFeeRate_MYieldFee(0);
        fuzz_wrap_MYieldToOne(558848450228315582151498391260153399989737721202685281484661715285615);
        fuzz_swapInM(6584524572527093903817352867478925546955370125905620513918320937317);
        fuzz_transfer_MYieldFee(18213736924916724488936775604594013997582162809437290225798442669049316);
        fuzz_approve_MYieldToOne(38);
        fuzz_approve_MEarnerManager(9774092287143063554314866740520482268207163700113208729051980388089);
        fuzz_wrap_MYieldFee(2296303862966420448427899319226166929296122074859479092083675725050246);
        fuzz_wrap_MYieldFee(0);
        fuzz_swapInToken(0);
        fuzz_claimFee_MYieldFee(353092818369047659244706650775941752517990858378885180867585679870752);
        fuzz_wrap_MYieldFee(0);
        fuzz_transferFrom_MYieldFee(0);
        fuzz_wrap_MYieldFee(111412919581802533587796022827913633736106955096128682937034966178835);
        fuzz_setFeeRecipient_MYieldFee(0);
        fuzz_claimFee_MYieldFee(68529654204595702090427217318771871648931085715671437668321771935482);
        fuzz_wrap_MYieldFee(1191);
        fuzz_setFeeRate_MYieldFee(44484621171076724205677706257935677359935888669807381287418563650594);
        fuzz_swap(4369999);
    }
}
