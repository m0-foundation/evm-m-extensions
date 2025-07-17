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
        fuzz_randomizeConfigs(1, 0, 0, 0, 0, 0); //1 for default config

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
        fuzz_randomizeConfigs(1, 0, 0, 0, 0, 0); //1 for default config

        setActor(USER2);
        fuzz_allLiquidityUni(1e6, 1e6, 0, 1, 1);
        setActor(USER2);
        fuzz_swapZeroToOne(1e6);
        setActor(USER2);
        fuzz_swapOneToZero(1e6);
    }

    // function test_coverage_MEarnerManager() public {
    //     fuzz_randomizeConfigs(1, 0, 0, 0, 0, 0); //1 for default config

    //     setActor(USER2);
    //     fuzz_wrap_MEarnerManager(1e6);
    //     setActor(USER2);
    //     fuzz_unwrap_MEarnerManager(1e6);
    // }

    // //696 wei diff
    // function test_repro_MYF_02_01() public {
    //     fuzz_randomizeConfigs(
    //         1,
    //         3531501269871057330480477762512317360590737170023638838882653578921318550,
    //         8738991855125593005696616203935380219576422863227710228581398787039825252,
    //         121206369707769632886350105251,
    //         1105,
    //         84896196756360711667673848097991896142252907096609311681565561525332913
    //     );
    //     fuzz_mint(0);
    //     fuzz_swapInToken(4078868152336378008090050440221702487879015075493307743052115081178091601);
    //     fuzz_warpWeeks(296728850958886128174596513823391020707863688085807041606311181234092195);
    //     fuzz_updateIndex_MYieldFee(0);
    //     fuzz_setFeeRate_MYieldFee(0);
    //     fuzz_setFeeRecipient_MYieldFee(2385);
    //     vm.warp(block.timestamp + 4);
    //     vm.roll(block.number + 1);
    //     fuzz_setFeeRate_MYieldFee(84339188778250192053393094097997937594893378026398072272151961);
    // }

    // //239 wei diff
    // function test_repro_MYF_02_02() public {
    //     fuzz_randomizeConfigs(
    //         64328701894630637431283885808928841890625919625630118301288,
    //         1477799979231960411239300943595099441264404253608819659784703772399,
    //         0,
    //         848600144863688483506631418384221899883777794645531215318647,
    //         0,
    //         0
    //     );
    //     fuzz_mint(0);
    //     fuzz_setFeeRate_MYieldFee(0);
    //     fuzz_warpWeeks(5137757999627636349167624565571586708270450651116721744822);
    //     fuzz_updateIndex_MYieldFee(147);
    //     fuzz_swapInToken(32947242190139113018588598329290106697324352456562824602595067842658109527);
    //     vm.warp(block.timestamp + 1);
    //     vm.roll(block.number + 1);
    //     fuzz_transferFrom_MYieldFee(4250067599402819121416816279145344529687550964723866);
    // }

    // //empty revert
    // function test_repro_ERR_05() public {
    //     fuzz_randomizeConfigs(
    //         214,
    //         0,
    //         46139851530136299821104842957382193093817762380570921117282,
    //         314308239068957744316647356466113707464008065684269011914,
    //         0,
    //         5699734427460219275805289678589792098012968748602344399106635829
    //     );
    //     fuzz_transferFrom_MEarnerManager(1157557441910141324905215018018224914169949006124364387748);
    //     fuzz_swapInM(357);
    //     fuzz_wrap_MYieldToOne(112519122023066331369637067621283068853023177427705228620944);
    //     fuzz_claimFor_MEarnerManager(0);
    //     fuzz_approve_MEarnerManager(6313932184356262734732150030564970445172546024410150);
    //     fuzz_approve_MYieldToOne(34966636763148461498061123506164691571770183508375626929);
    //     fuzz_setFeeRate_MYieldFee(0);
    //     fuzz_unwrap_MYieldFee(17238370822720362770923335465179892242824249651730147356740);
    //     fuzz_swapInToken(0);
    //     fuzz_claimYieldFor_MYieldFee(0);
    //     fuzz_setFeeRecipient_MEarnerManager(0);
    //     fuzz_swapOutM(239508740197428772753125517607262116608997363572270);
    //     fuzz_transferFrom_MYieldFee(503157157443067693306812187332980908600862787650858);
    //     fuzz_approve_MYieldFee(89650225098794334306968545749099670967737160);
    //     fuzz_swapInM(12858633147676179606219013877472126945043000376157292);
    //     fuzz_unwrap_MEarnerManager(0);
    //     fuzz_transferFrom_MYieldToOne(0);
    //     fuzz_swapOutToken(276);
    // }

    // function test_repro_SWAP_01_01() public {
    //     fuzz_randomizeConfigs(
    //         16889982,
    //         17,
    //         5135712976829093906714751586228984909652221499046955234609293173426,
    //         1885464081798406194406093808409621094022553010545021677056038872593585,
    //         602,
    //         208788563053346195690184550654170768619812790219093969630516114340936476
    //     );
    //     fuzz_wrap_MYieldToOne(1435806453141873707353109937312094802261543082180546311247880316529884);
    //     fuzz_claimFor_MEarnerManager(0);
    //     fuzz_approve_MEarnerManager(1444104708871071380759731938026658565090585885859654271389124727779150140);
    //     fuzz_approve_MYieldToOne(70781279844310365134270049383027054761492082023683192992915202027442);
    //     fuzz_setFeeRate_MYieldFee(18);
    //     fuzz_unwrap_MYieldFee(436217437293928803189570493977897400847686566226280298144747573364020);
    //     fuzz_swapInToken(0);
    //     fuzz_setFeeRecipient_MEarnerManager(0);
    //     fuzz_transferFrom_MYieldFee(7794570933629331364239825628018257313863613235891206769570478466);
    //     fuzz_approve_MYieldFee(223006492224911575021572134845016533929530898393289670748683532697812528);
    //     fuzz_unwrap_MEarnerManager(0);
    //     fuzz_transferFrom_MYieldToOne(0);
    //     fuzz_swapInToken(87931809805384849450436888619741364982333737947665155336059015680070348990886);
    //     fuzz_claimFor_MEarnerManager(0);
    //     fuzz_setYieldRecipient_MYieldToOne(10290207330412922900630497077039110685590450581207222354671059894340);
    //     fuzz_approve_MYieldToOne(3178);
    //     fuzz_wrap_MYieldFee(5805555141084068736118080556377450849038535152556052143581106876850334);
    //     fuzz_mint(326);
    //     fuzz_setFeeRecipient_MEarnerManager(0);
    //     fuzz_mint(0);
    //     fuzz_transfer_MYieldFee(274337193405203412239645247591855087812999593732771367888345271144722455);
    //     fuzz_updateIndex_MYieldFee(103520995092677296904761193009355058809249459009690344349026359916494699);
    //     fuzz_transferFrom_MYieldToOne(570732959574702872425009437491501210405336825868063981133150324727061);
    //     fuzz_unwrap_MYieldFee(676715584872707230499184631066522480483040450080326972742348659);
    //     fuzz_swapOutToken(0);
    //     fuzz_approve_MEarnerManager(0);
    //     fuzz_unwrap_MYieldFee(1133895458298441221529213351095725193078419059030231603932355);
    //     fuzz_unwrap_MYieldToOne(6585685458379937842485079661450915963887271151236633640331165141047);
    //     fuzz_swapInM(16813169870453600717030958688739576033474993308517418588203931539844);
    //     fuzz_claimFor_MEarnerManager(56297868697416768162444499844834294120246972801157556229915646367317);
    //     fuzz_setFeeRecipient_MEarnerManager(0);
    //     fuzz_swapOutToken(82344110991946060678805380985876333552179925932371071359310843539724);
    //     vm.warp(block.timestamp + 52);
    //     vm.roll(block.number + 22408);
    //     fuzz_claimYieldFor_MYieldFee(0);
    //     fuzz_setFeeRate_MYieldFee(0);
    //     fuzz_wrap_MYieldToOne(558848450228315582151498391260153399989737721202685281484661715285615);
    //     fuzz_swapInM(6584524572527093903817352867478925546955370125905620513918320937317);
    //     fuzz_transfer_MYieldFee(18213736924916724488936775604594013997582162809437290225798442669049316);
    //     fuzz_approve_MYieldToOne(38);
    //     fuzz_approve_MEarnerManager(9774092287143063554314866740520482268207163700113208729051980388089);
    //     fuzz_wrap_MYieldFee(2296303862966420448427899319226166929296122074859479092083675725050246);
    //     fuzz_wrap_MYieldFee(0);
    //     fuzz_swapInToken(0);
    //     fuzz_claimFee_MYieldFee(353092818369047659244706650775941752517990858378885180867585679870752);
    //     fuzz_wrap_MYieldFee(0);
    //     fuzz_transferFrom_MYieldFee(0);
    //     fuzz_wrap_MYieldFee(111412919581802533587796022827913633736106955096128682937034966178835);
    //     fuzz_setFeeRecipient_MYieldFee(0);
    //     fuzz_claimFee_MYieldFee(68529654204595702090427217318771871648931085715671437668321771935482);
    //     fuzz_wrap_MYieldFee(1191);
    //     fuzz_setFeeRate_MYieldFee(44484621171076724205677706257935677359935888669807381287418563650594);
    //     fuzz_swap(4369999);
    // }

    // function test_repro_MEARN_01_01() public {
    //     fuzz_randomizeConfigs(
    //         6137315177589154732490630832331181022026443,
    //         8598501472775551343330124556124617893,
    //         0,
    //         1393493721370785808970641800088862821687,
    //         0,
    //         0
    //     );
    //     fuzz_mint(0);
    //     fuzz_swapInToken(481554925443102584638065656772743995775045569639796806990609991);
    //     vm.warp(block.timestamp + 1);
    //     vm.roll(block.number + 1);
    //     fuzz_approve_MEarnerManager(0);
    // }

    // function test_repro_MEARN_01_02() public {
    //     fuzz_randomizeConfigs(
    //         40246611287728766319870156159623069559604027194954027335826196309811632,
    //         54095159985309625025878896947808393802403544285106232120009354624020310,
    //         734360242295892608411769658234088723440907589093877202163748469296,
    //         8,
    //         99015056422881560636667051816649355952351030646386994874449293691880,
    //         20860560551309167679074541592155277035361877263769071624209784565387385
    //     );
    //     fuzz_setFeeRate_MYieldFee(22841866284516787073062511456609994464118909649900926824260);
    //     fuzz_unwrap_MYieldFee(39347124717939034253153352201338789748022322890247057529462715);
    //     fuzz_approve_MYieldToOne(0);
    //     fuzz_swapOutM(0);
    //     fuzz_claimYield_MYieldToOne(0);
    //     fuzz_transferFrom_MYieldToOne(0);
    //     fuzz_claimFee_MYieldFee(9591314298008357636432064593140217298604186456336692972115844967);
    //     fuzz_setYieldRecipient_MYieldToOne(10304598767627640819187198579255386518947227174315976543075);
    //     fuzz_wrap_MYieldToOne(0);
    //     fuzz_setFeeRecipient_MYieldFee(0);
    //     fuzz_transfer_MYieldFee(0);
    //     fuzz_swapOutM(22153220723688848640578527293);
    //     fuzz_claimYield_MYieldToOne(93656484374227799187485667574266563607624705775215839338152975);
    //     fuzz_approve_MYieldToOne(1469473534496630939576506880684555715036194288541481046432952617);
    //     fuzz_transfer_MYieldToOne(10365884861123432718346732487475118944871657385079670525261094567703);
    //     fuzz_transfer_MYieldToOne(4621249394570291358730008874099209961755107282682481297668426547336);
    //     fuzz_transfer_MYieldFee(0);
    //     fuzz_unwrap_MYieldFee(0);
    //     fuzz_claimFee_MYieldFee(873203860655107182375740209343205733082872314339909583680202083422);
    //     fuzz_claimFor_MEarnerManager(2690319028686937252362020012954072980954430689002357413931174);
    //     fuzz_transferFrom_MEarnerManager(168262828508480608760210090433858675405251870319445103084083180213);
    //     fuzz_swapInToken(2019894408335823759712771591249359689994923733136396768093498463549445684704);
    //     fuzz_approve_MYieldToOne(102565703052124193496892677299573900496091730614285109622153667);
    //     fuzz_transfer_MEarnerManager(0);
    //     fuzz_transferFrom_MEarnerManager(0);
    //     fuzz_setFeeRate_MYieldFee(0);
    //     fuzz_claimFee_MYieldFee(9704009740922932077387326163454634400452391543183602289979);
    //     fuzz_unwrap_MYieldFee(2);
    //     fuzz_transfer_MEarnerManager(128605604275293105908259226019497694024962483085478884826616831);
    //     fuzz_approve_MEarnerManager(1674162603373364321837831188152371642599444809208062949095291303266);
    //     fuzz_mint(0);
    //     vm.warp(block.timestamp + 8090);
    //     vm.roll(block.number + 1);
    //     fuzz_swapInM(0);
    //     fuzz_unwrap_MEarnerManager(182942293691309912262199429359920657193617377011579917);
    //     fuzz_swap(0);
    //     fuzz_wrap_MYieldToOne(0);
    //     fuzz_wrap_MYieldToOne(8738431265425090749421884741245250956327224115926921482267277);
    //     fuzz_swapOutM(379157798);
    // }

    // function test_repro_MEARN_01_03() public {
    //     fuzz_randomizeConfigs(
    //         27673522789833916321092532199235262150450920778624173877210436,
    //         2014928862487291256060739131696895629098978422363188587828136141325,
    //         8263567180622913807728850375929294826554376943462229916690577973,
    //         163009216592090965749794145872358292694574861900441255832031365,
    //         2866822279940303429264945548729993702410315619510853927683867,
    //         0
    //     );
    //     fuzz_setYieldRecipient_MYieldToOne(289454429864047125616787798498275688971718867799636905957);
    //     fuzz_transferFrom_MEarnerManager(17479166801010618785003712460779018573644594587472866531);
    //     fuzz_transferFrom_MYieldFee(0);
    //     fuzz_unwrap_MYieldFee(487918589753582027523287545448844790331400219072193295991882);
    //     fuzz_swapOutM(0);
    //     fuzz_swap(0);
    //     fuzz_claimYieldFor_MYieldFee(107675132948726630929437673036773792582534653957546162713);
    //     fuzz_setFeeRecipient_MYieldFee(0);
    //     fuzz_swapInM(31492796);
    //     fuzz_unwrap_MEarnerManager(16658282839945084181579166918444218652995677105997652644803679);
    //     fuzz_swapInToken(0);
    //     fuzz_mint(0);
    //     fuzz_unwrap_MEarnerManager(267940848237754355477);
    //     fuzz_unwrap_MEarnerManager(4667220875070352953710116241501080101606481664322760);
    //     vm.warp(block.timestamp + 1);
    //     vm.roll(block.number + 2);
    //     fuzz_mint(0);
    //     fuzz_mint(52448);
    //     fuzz_swapInM(114683625634695032426454765338116813412133925420360582116893);
    //     fuzz_unwrap_MYieldFee(0);
    //     fuzz_wrap_MEarnerManager(492677674487883841139225015988984353730663350226448201214570);
    //     fuzz_wrap_MYieldToOne(3793655209343906650629158100050178595907967605940992362935);
    //     fuzz_mint(0);
    //     fuzz_swap(351356);
    // }
}
