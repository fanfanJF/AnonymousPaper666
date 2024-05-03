

import time
def get_property(data, i, block_type):
    prop = {}
    #print(data[i], block_type)
    k = i
    timeout = time.time() + 5
    while data[k].replace(' ', '')[:6] == '<PName':
        if time.time() > timeout:
            break
        if block_type == 'Gain':
            if "Gain" in data[k]:
                prop["Gain"] = data[k].split('"Gain"')[1].replace('</P>', '').replace('>', '')
            if "SaturateOnIntegerOverflow" in data[k]:
                prop["SaturateOnIntegerOverflow"] = data[k].split('"SaturateOnIntegerOverflow"')[1].replace('</P>', '').replace('>', '')
            # if "OutDataTypeStr" in data[k]:
            #     print(data[k],'OutDataTypeStr')
            #     prop["OutDataTypeStr"] = data[k].split('"OutDataTypeStr"')[1].replace('</P>', '').replace('>', '')
        if block_type == 'Goto':
            if "GotoTag" in data[k]:
                prop["GotoTag"] = data[k].split('"GotoTag"')[1].replace('</P>', '').replace('>', '')
        if block_type == 'Sum':
            if "SaturateOnIntegerOverflow" in data[k]:
                try:
                    prop["SaturateOnIntegerOverflow"] = data[k].split('"SaturateOnIntegerOverflow"')[1].replace('</P>', '').replace('>', '')
                except:
                    print(k,len(data),data[k])
            if "Inputs" in data[k]:
                prop["Inputs"] = data[k].split('"Inputs"')[1].replace('</P>', '').replace('>', '')
        if block_type == 'Switch':
            if "Threshold" in data[k]:
                try:
                    prop["Threshold"] = data[k].split('"Threshold"')[1].replace('</P>', '').replace('>', '')
                except:  # not in Name="Threshold"
                    continue
            if "SaturateOnIntegerOverflow" in data[k]:
                prop["SaturateOnIntegerOverflow"] = data[k].split('"SaturateOnIntegerOverflow"')[1].replace('</P>', '').replace('>', '')
            # if "OutDataTypeStr" in data[k]:
            #     print(data[k],'OutDataTypeStr')
            #     prop["OutDataTypeStr"] = data[k].split('"OutDataTypeStr"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'UnitDelay':
            if "SampleTime" in data[k]:
                prop["SampleTime"] = data[k].split('"SampleTime"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'From':
            if "GotoTag" in data[k]:
                prop["GotoTag"] = data[k].split('"GotoTag"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'Product':
            if "SaturateOnIntegerOverflow" in data[k]:
                prop["SaturateOnIntegerOverflow"] = data[k].split('"SaturateOnIntegerOverflow"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'Sin':
            if "Amplitude" in data[k]:
                prop["Amplitude"] = data[k].split('"Amplitude"')[1].replace('</P>', '').replace('>', '')
            if "Frequency" in data[k]:
                prop["Frequency"] = data[k].split('"Frequency"')[1].replace('</P>', '').replace('>', '')
            if "SampleTime" in data[k]:
                prop["SampleTime"] = data[k].split('"SampleTime"')[1].replace('</P>', '').replace('>', '')

        # can extract OutDataTypeStr
        if block_type == 'Constant':
            if "Value" in data[k]:
                prop["Value"] = data[k].split('"Value"')[1].replace('</P>', '').replace('>', '')
            if "OutDataTypeStr" in data[k]:
                prop["OutDataTypeStr"] = data[k].split('"OutDataTypeStr"')[1].replace('</P>', '').replace('>', '')

        # can extract OutDataTypeStr
        if block_type == 'RelationalOperator':
            if "Operator" in data[k]:
                prop["Operator"] = data[k].split('"Operator"')[1].replace('</P>', '').replace('>', '')
            if "OutDataTypeStr" in data[k]:
                prop["OutDataTypeStr"] = data[k].split('"OutDataTypeStr"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'Abs':
            if "SaturateOnIntegerOverflow" in data[k]:
                prop["SaturateOnIntegerOverflow"] = data[k].split('"SaturateOnIntegerOverflow"')[1].replace('</P>', '').replace('>', '')

        if block_type == 'Saturate':
            if "UpperLimit" in data[k]:
                prop["UpperLimit"] = data[k].split('"UpperLimit"')[1].replace('</P>', '').replace('>', '')
            if "LowerLimit" in data[k]:
                prop["LowerLimit"] = data[k].split('"LowerLimit"')[1].replace('</P>', '').replace('>', '')

        # can extract OutDataTypeStr
        if block_type == 'Logic':
            if "Operator" in data[k]:
                prop["Operator"] = data[k].split('"Operator"')[1].replace('</P>', '').replace('>', '')
            if "OutDataTypeStr" in data[k]:
                prop["OutDataTypeStr"] = data[k].split('"OutDataTypeStr"')[1].replace('</P>', '').replace('>', '')

        k+=1
    #print(block_type, prop)
    return prop


