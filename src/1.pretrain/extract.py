
from type_map import get_property


def process_system(data):
    total_nodes = {}


    node_system_count = 0


    stats_map = {0: 'graph0'}  # {0: '<System>', 1: '<SubSystem>', 2: '<SubSubSystem>', 3: '<SubSubSubSystem>', 4: '<SubSubSubSubSystem>'}
    for idx in range(1, 1000):
        stats_map[idx] = f'graph{idx}'
    global outport_SIDs
    outport_SIDs = []


    def parse_block(i, stats):
        # global node_system_count_reverse
        global outport_SIDs

        cur_line = data[i]


        while cur_line.replace(' ', '')[:6] != '<Block':
            try:
                cur_line = data[i]

                if 'System' in data[i+1]:

                    return False, i

                i+=1
            except:
                break

        block_line = cur_line.split(' ')


        node = {}
        for item in block_line:
            if 'BlockType' in item:
                blocktype = item.split('=')[1].replace('"', '').replace('>', '')
                node['BlockType'] = blocktype
            if 'Name' in item:
                name = item.split('=')[1].replace('"', '').replace('>', '')
                node['Name'] = name
            if 'SID' in item:
                sid = item.split('=')[1].replace('"', '').replace('>', '')
                if ':' in sid:
                    continue
                node['SID'] = int(sid)


        if node != {}:
            property = get_property(data, i, node['BlockType'])

            if property != {}:
                node['property'] = property

            #if node['SID'] not in outport_SIDs:

            if not total_nodes.get(stats):
                total_nodes[stats] = [node]
            else:
                total_nodes[stats].append(node)



        if 'System' not in data[i + 1]:
            return True, i

    import time
    timeout = time.time() + 5
    # node extraction
    i = 0
    while i < len(data) - 1:
        line = data[i].strip()

        timeout = time.time() + 5

        if line.replace(' ', '') == '<System>':
            if time.time() > timeout:
                continue

            node_stats = stats_map[node_system_count]
            node_system_count += 1

            res, i = parse_block(i, node_stats)


            while res:
                i += 1
                try:
                    res, i = parse_block(i, node_stats)
                except:
                    break

        i += 1


    return total_nodes if total_nodes != {} else None

