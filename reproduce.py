import re


def convert_to_solidity(call_sequence):
    # Regex patterns to extract the necessary parts
    call_pattern = re.compile(
        r"(?:Fuzz\.)?(\w+\([^\)]*\))(?: from: (0x[0-9a-fA-F]{40}))?(?: Gas: (\d+))?(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?"
    )
    wait_pattern = re.compile(
        r"\*wait\*(?: Time delay: (\d+) seconds)?(?: Block delay: (\d+))?"
    )

    solidity_code = "function test_repro() public {\n"

    lines = call_sequence.strip().split("\n")
    last_index = len(lines) - 1

    for i, line in enumerate(lines):
        call_match = call_pattern.search(line)
        wait_match = wait_pattern.search(line)
        if call_match:
            call, from_addr, gas, time_delay, block_delay = call_match.groups()

            # Add prank line if from address exists
            # if from_addr:
            #     solidity_code += f'    vm.prank({from_addr});\n'

            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f"    vm.warp(block.timestamp + {time_delay});\n"

            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f"    vm.roll(block.number + {block_delay});\n"

            if "collateralToMarketId" in call:
                continue

            # Add function call
            if i < last_index:
                solidity_code += f"    try this.{call} {{}} catch {{}}\n"
            else:
                solidity_code += f"    {call};\n"
            solidity_code += "\n"
        elif wait_match:
            time_delay, block_delay = wait_match.groups()

            # Add warp line if time delay exists
            if time_delay:
                solidity_code += f"    vm.warp(block.timestamp + {time_delay});\n"

            # Add roll line if block delay exists
            if block_delay:
                solidity_code += f"    vm.roll(block.number + {block_delay});\n"
            solidity_code += "\n"

    solidity_code += "}\n"

    return solidity_code


# Example usage
call_sequence = """
Fuzz.fuzz_swapOutToken(55399568478761234298325923228940735636046691746140481670162894136160329760806) from: 0x0000000000000000000000000000000000010000 «USER1» Time delay: 82671 seconds Block delay: 54809
Fuzz.fuzz_swapOutToken(4370000) from: 0x0000000000000000000000000000000000010000 «USER1» Time delay: 254414 seconds Block delay: 24311
Fuzz.fuzz_swapOutToken(365419150) from: 0x0000000000000000000000000000000000010000 «USER1» Time delay: 209930 seconds Block delay: 11905
Fuzz.fuzz_swapOutToken(1524785993) from: 0x0000000000000000000000000000000000010000 «USER1» Time delay: 24867 seconds Block delay: 53166
Fuzz.fuzz_swapInToken(111186113090825993895176355630265163115409952367750162817411463516766348748081) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 206186 seconds Block delay: 7323
Fuzz.fuzz_swapInToken(58518686489386371937806802943650499245489709554198854239297641201831285085019) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 332369 seconds Block delay: 1362
Fuzz.fuzz_swapOutToken(41986418787272719855678982917395829065749306276092823157825951477792264907273) from: 0x0000000000000000000000000000000000020000 «USER2» Time delay: 487078 seconds Block delay: 127
Fuzz.fuzz_swapInToken(113368692686126429944411275222214350560866025461109335104412918644869186562556) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 407328 seconds Block delay: 19933
Fuzz.fuzz_swapOutToken(1524785992) from: 0x0000000000000000000000000000000000010000 «USER1» Time delay: 566039 seconds Block delay: 53011
Fuzz.fuzz_swapInToken(1524785992) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 82672 seconds Block delay: 53166
Fuzz.fuzz_swapInToken(1524785993) from: 0x0000000000000000000000000000000000020000 «USER2» Time delay: 254414 seconds Block delay: 127
Fuzz.fuzz_swapOutToken(1524785993) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 136393 seconds Block delay: 42101
Fuzz.fuzz_swapOutToken(102873395405339786280708947952107872766714396236775883733964860159599775617759) from: 0x0000000000000000000000000000000000020000 «USER2» Time delay: 522178 seconds Block delay: 47740
Fuzz.fuzz_swapOutToken(73407013913466170030877599963887444936118138462387507240356937912100743926293) from: 0x0000000000000000000000000000000000020000 «USER2» Time delay: 420078 seconds Block delay: 12493
Fuzz.fuzz_swapOutToken(4516468113242658428694319542670603196965338175661055576754285340787670256843) from: 0x0000000000000000000000000000000000030000 «USER3» Time delay: 436727 seconds Block delay: 23885
"""

solidity_code = convert_to_solidity(call_sequence)
print(solidity_code)
