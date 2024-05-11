import pandas as pd
import json
import matplotlib.pyplot as plt

def total_analysis(model):
    def analysis(model, mut, type):
        df = pd.read_csv(f'./{model}/TS{mut}_{type}.csv')
        total_num = len(df['killed'].tolist())
        num_killed = df['killed'].tolist().count(1)

        res = {}
        tcs = df['tests that killed'].tolist()
        names = df['mutant name'].tolist()
        for name, tc_ in zip(names, tcs):
            try:
                tc = tc_.split(',')
            except:
                continue
            if tc==[' ']:
                continue
            tc = [int(item.split('_')[1]) for item in tc if item != '']
            for i in tc:
                if res.get(i):
                    res[i].append(name)
                else:
                    res[i] = [name]
        TS = set(sorted(list(res.keys())))
        return num_killed, total_num, TS

    if model not in ['AECS']:
        num_killed_bert_fitness, total_num_bert_fitness, TSbert_fitness = analysis(model, 'bert', 'fitness')
        num_killed_FIM_fitness, total_num_FIM_fitness, TSFIM_fitness = analysis(model, 'FIM', 'fitness')
    else:
        num_killed_bert_fitness, total_num_bert_fitness, TSbert_fitness = 0, 0, ()
        num_killed_FIM_fitness, total_num_FIM_fitness, TSFIM_fitness = 0, 0, ()

    num_killed_bert_output, total_num_bert_output, TSbert_output = analysis(model, 'bert', 'output')
    num_killed_FIM_output, total_num_FIM_output, TSFIM_output = analysis(model, 'FIM', 'output')

    if model not in ['fsm', 'AECS']:
        num_killed_bert_req, total_num_bert_req, TSbert_req = analysis(model, 'bert', 'req')
        num_killed_FIM_req, total_num_FIM_req, TSFIM_req = analysis(model, 'FIM', 'req')
    else:
        num_killed_bert_req, total_num_bert_req, TSbert_req = 0, 0, ()
        num_killed_FIM_req, total_num_FIM_req, TSFIM_req = 0, 0, ()

    result_fitness = {}
    result_fitness['number of compiled mutants'] = [total_num_bert_fitness, total_num_FIM_fitness]
    result_fitness['number of killed mutants'] = [num_killed_bert_fitness, num_killed_FIM_fitness]
    if model not in ['AECS']:
        result_fitness['observation effort'] = [
        (total_num_bert_fitness - num_killed_bert_fitness)/total_num_bert_fitness,
        (total_num_FIM_fitness - num_killed_FIM_fitness)/total_num_FIM_fitness]
    else:
        result_fitness['observation effort'] = ['0','0']

    result_fitness['number of test cases in TSBert/TSFIM'] = [len(TSbert_fitness), len(TSFIM_fitness)]

    result_output = {}
    result_output['number of compiled mutants'] = [total_num_bert_output, total_num_FIM_output]
    result_output['number of killed mutants'] = [num_killed_bert_output, num_killed_FIM_output]

    result_output['observation effort'] = [
        (total_num_bert_output - num_killed_bert_output)/total_num_bert_output,
        (total_num_FIM_output - num_killed_FIM_output)/total_num_FIM_output]
    result_output['number of test cases in TSBert/TSFIM'] = [len(TSbert_output), len(TSFIM_output)]

    result_req = {}
    result_req['number of compiled mutants'] = [total_num_bert_req, total_num_FIM_req]
    result_req['number of killed mutants'] = [num_killed_bert_req, num_killed_FIM_req]
    if model not in ['fsm', 'AECS']:
        result_req['observation effort'] = [(total_num_bert_req - num_killed_bert_req)/total_num_bert_req,
                                            (total_num_FIM_req - num_killed_FIM_req)/total_num_FIM_req]
    else:
        result_req['observation effort'] = ['0','0']

    result_req['number of test cases in TSBert/TSFIM'] = [len(TSbert_req), len(TSFIM_req)]

    def trans_to_int(dictionary):
        new_dict = {}
        for key, value in dictionary.items():
            int_key = int(key)
            int_value = [int(item) for item in value] if isinstance(value, list) else int(value)
            new_dict[int_key] = int_value
        return new_dict

    def extract_tc_and_muts(dictionary, TS):  # choose intersection
        test_cases = []
        total_killed_muts = set()
        from collections import defaultdict
        tc2mut = defaultdict(set)
        for tc, killed_muts in dictionary.items():
            if killed_muts != []:
                if tc not in TS:
                    continue
                for mut in killed_muts:
                    total_killed_muts.add(mut)
                    tc2mut[tc].add(mut)
                test_cases.append(tc)

        tc2mut = {k:list(v) for k,v in tc2mut.items()}
        return set(test_cases), list(total_killed_muts), tc2mut

    if model not in ['AECS']:
        tcbert_kill_fim_fitness_ = trans_to_int(json.load(open(f'{model}/tcbert_kill_fim_fitness.json')))
    tcbert_kill_fim_output_ = trans_to_int(json.load(open(f'{model}/tcbert_kill_fim_output.json')))
    tcfim_kill_bert_output_ = trans_to_int(json.load(open(f'{model}/tcfim_kill_bert_output.json')))
    if model not in ['AECS']:
        tcfim_kill_bert_fitness_ = trans_to_int(json.load(open(f'{model}/tcfim_kill_bert_fitness.json')))
    if model not in ['fsm', 'AECS']:
        tcbert_kill_fim_req_ = trans_to_int(json.load(open(f'{model}/tcbert_kill_fim_req.json')))
        tcfim_kill_bert_req_ = trans_to_int(json.load(open(f'{model}/tcfim_kill_bert_req.json')))


    tcbert_kill_fim_output, killed_muts1,tc2mut1 = extract_tc_and_muts(tcbert_kill_fim_output_, TSbert_output)
    tcfim_kill_bert_output, killed_muts2, tc2mut2 = extract_tc_and_muts(tcfim_kill_bert_output_, TSFIM_output)
    if model not in ['AECS']:
        tcbert_kill_fim_fitness, killed_muts3, tc2mut3 = extract_tc_and_muts(tcbert_kill_fim_fitness_, TSbert_fitness)
        tcfim_kill_bert_fitness, killed_muts4, tc2mut4 = extract_tc_and_muts(tcfim_kill_bert_fitness_, TSFIM_fitness)
    else:
        killed_muts3, killed_muts4 = 0, 0
        tcbert_kill_fim_fitness = {}
        tcfim_kill_bert_fitness = {}
        tc2mut3=None
        tc2mut4=None
    if model not in ['fsm', 'AECS']:
        tcbert_kill_fim_req, killed_muts5, tc2mut5 = extract_tc_and_muts(tcbert_kill_fim_req_, TSbert_req)
        tcfim_kill_bert_req, killed_muts6, tc2mut6 = extract_tc_and_muts(tcfim_kill_bert_req_, TSFIM_req)
    else:
        killed_muts5, killed_muts6 = 0, 0
        tcbert_kill_fim_req = {}
        tcfim_kill_bert_req = {}
        tc2mut5=None
        tc2mut6=None

    result_output['Ratio of killing mutants of the other approach'] = [
        round(len(killed_muts1) / total_num_FIM_output, 2),
        round(len(killed_muts2) / total_num_bert_output, 2)]
    if model not in ['AECS']:
        result_fitness['Ratio of killing mutants of the other approach'] = [
        round(len(killed_muts3) / total_num_FIM_fitness, 2),
        round(len(killed_muts4) / total_num_bert_fitness, 2)]
    else:
        result_fitness['Ratio of killing mutants of the other approach'] = [
            0,
            0]

    if model not in ['fsm', 'AECS']:
        result_req['Ratio of killing mutants of the other approach'] = [
            round(len(killed_muts5) / total_num_FIM_req, 2),
            round(len(killed_muts6) / total_num_bert_req, 2)]
    else:
        result_req['Ratio of killing mutants of the other approach'] = [
            0,
            0]


    result_output['Mutation coverage of the other approach'] = [len(tcbert_kill_fim_output)/len(TSbert_output),
                                                                len(tcfim_kill_bert_output)/len(TSFIM_output)]

    if model not in ['AECS']:
        result_fitness['Mutation coverage of the other approach'] = [
        len(tcbert_kill_fim_fitness)/len(TSbert_fitness),
        len(tcfim_kill_bert_fitness)/len(TSFIM_fitness)]
    else:
        result_fitness['Mutation coverage of the other approach'] = ['0', '0']

    if model not in ['fsm', 'AECS']:
        result_req['Mutation coverage of the other approach'] = [len(tcbert_kill_fim_req)/len(TSbert_req),
                                                                 len(tcfim_kill_bert_req)/len(TSFIM_req)]
    else:
        result_req['Mutation coverage of the other approach'] = ['0', '0']

    try:
        tcbert_violate_original_req = set([int(item.strip()) for item in open(f'{model}/bert_violate_req.txt').readlines()])
    except:
        tcbert_violate_original_req = {}
    try:
        tcFIM_violate_original_req = set([int(item.strip()) for item in open(f'{model}/FIM_violate_req.txt').readlines()])
    except:
        tcFIM_violate_original_req = {}

    violated_TSbert_output = tcbert_violate_original_req.intersection(TSbert_output)
    violated_TSbert_fitness = tcbert_violate_original_req.intersection(TSbert_fitness)
    violated_TSbert_req = tcbert_violate_original_req.intersection(TSbert_req)
    violated_TSFIM_output = tcFIM_violate_original_req.intersection(TSFIM_output)
    violated_TSFIM_fitness = tcFIM_violate_original_req.intersection(TSFIM_fitness)
    violated_TSFIM_req = tcFIM_violate_original_req.intersection(TSFIM_req)


    result_output['Faults revealing ability for original model'] = [
        len(violated_TSbert_output)/len(TSbert_output),
        len(violated_TSFIM_output)/len(TSFIM_output)]

    result_fitness['Faults revealing ability for original model'] = [
        len(violated_TSbert_fitness)/(len(TSbert_fitness)+1e-10),
        len(violated_TSFIM_fitness)/(len(TSFIM_fitness)+1e-10)]

    if model not in ['fsm', 'AECS']:
        result_req['Faults revealing ability for original model'] = [len(violated_TSbert_req)/len(TSbert_req),
                                                                     len(violated_TSFIM_req)/len(TSFIM_req)]
    else:
        result_req['Faults revealing ability for original model'] = ['0', '0']

    # print('output:')
    # print(result_output)
    #
    # print('fitness:')
    # print(result_fitness)
    #
    # print('req:')
    # print(result_req)
    tcs = [TSbert_output, TSFIM_output,
           TSbert_fitness, TSFIM_fitness,
           TSbert_req, TSFIM_req]
    tc2muts = [tc2mut1, tc2mut2, tc2mut3, tc2mut4, tc2mut5, tc2mut6]

    return {'output':result_output,'fitness':result_fitness,
            'req':result_req,'tc':tcs, 'tc2muts':tc2muts}



total_out_res={'number of compiled mutants': [0, 0], 'number of killed mutants': [0, 0],
               'observation effort': [0, 0], 'number of test cases in TSBert/TSFIM': [0, 0],
               'Ratio of killing mutants of the other approach': [0, 0],
               'Mutation coverage of the other approach': [0, 0],
               'Faults revealing ability for original model': [0, 0]}
total_fit_res={'number of compiled mutants': [0, 0], 'number of killed mutants': [0, 0],
               'observation effort': [0, 0], 'number of test cases in TSBert/TSFIM': [0, 0],
               'Ratio of killing mutants of the other approach': [0, 0],
               'Mutation coverage of the other approach': [0, 0],
               'Faults revealing ability for original model': [0, 0]}
total_req_res={'number of compiled mutants': [0, 0], 'number of killed mutants': [0, 0],
               'observation effort': [0, 0], 'number of test cases in TSBert/TSFIM': [0, 0],
               'Ratio of killing mutants of the other approach': [0, 0],
               'Mutation coverage of the other approach': [0, 0],
               'Faults revealing ability for original model': [0, 0]}

def map_tc(model_name,tc_):
    return [f'{model_name}_tc{str(_)}' for _ in tc_]



all_TS_bert_output=0
all_TS_bert_fit=0
all_TS_bert_req = 0

all_TS_FIM_output=0
all_TS_FIM_fit=0
all_TS_FIM_req = 0

all_TS_inter_output = 0
all_TS_inter_fit = 0
all_TS_inter_req = 0

total_inter_out_len = 0
total_bert_out_len=0
total_fim_out_len=0

total_inter_fit_len = 0
total_bert_fit_len=0
total_fim_fit_len=0

total_inter_req_len = 0
total_bert_req_len=0
total_fim_req_len=0

model_list = ['tustin', 'twotanks', 'ATCS', 'fsm', 'AECS']
for model in model_list:
    result=total_analysis(model)
    for type, res in result.items():
        if type == 'output':
            for name, item in res.items():
                val = total_out_res[name]
                val0 = float(item[0])
                val1 = float(item[1])
                if name not in ['number of compiled mutants', 'number of killed mutants']:
                    val0 /= len(model_list)
                    val1 /= len(model_list)
                else:
                    val0 = int(val0)
                    val1 = int(val1)
                val[0] += val0
                val[1] += val1
                total_out_res[name] = val
        if type == 'fitness':
            for name, item in res.items():
                val = total_fit_res[name]
                val0 = float(item[0])
                val1 = float(item[1])
                if name not in ['number of compiled mutants', 'number of killed mutants']:
                    val0 /= len(model_list)
                    val1 /= len(model_list)
                else:
                    val0 = int(val0)
                    val1 = int(val1)

                val[0] += val0
                val[1] += val1
                total_fit_res[name] = val
        if type == 'req':
            for name, item in res.items():
                val = total_req_res[name]
                val0 = float(item[0])
                val1 = float(item[1])
                if name not in ['number of compiled mutants', 'number of killed mutants']:
                    val0 /= len(model_list)
                    val1 /= len(model_list)
                else:
                    val0 = int(val0)
                    val1 = int(val1)
                val[0] += val0
                val[1] += val1
                total_req_res[name] = val

        if type == 'tc':
            TSbert_output, TSFIM_output, TSbert_fitness, TSFIM_fitness, TSbert_req, TSFIM_req =\
                res

            if model=='tustin':
                tsmain_num=40
            else:
                tsmain_num=20

            TSbert_output_only = set(TSbert_output) - set(TSFIM_output)
            TSFIM_output_only = set(TSFIM_output) - set(TSbert_output)
            TS_inter_output = set(TSFIM_output) & set(TSbert_output)
            all_TS_bert_output += len(TSbert_output_only)/tsmain_num
            all_TS_FIM_output += len(TSFIM_output_only)/tsmain_num
            all_TS_inter_output += len(TS_inter_output)/tsmain_num

            TSbert_fit_only = set(TSbert_fitness) - set(TSFIM_fitness)
            TSFIM_fit_only = set(TSFIM_fitness) - set(TSbert_fitness)
            TS_inter_fit = set(TSFIM_fitness) & set(TSbert_fitness)
            all_TS_bert_fit+=len(TSbert_fit_only)/tsmain_num
            all_TS_FIM_fit+=len(TSFIM_fit_only)/tsmain_num
            all_TS_inter_fit += len(TS_inter_fit)/tsmain_num

            TSbert_req_only = set(TSbert_req) - set(TSFIM_req)
            TSFIM_req_only = set(TSFIM_req) - set(TSbert_req)
            TS_inter_req = set(TSFIM_req) & set(TSbert_req)
            all_TS_bert_req+=len(TSbert_req_only)/tsmain_num
            all_TS_FIM_req+=len(TSFIM_req_only)/tsmain_num
            all_TS_inter_req += len(TS_inter_req)/tsmain_num

        if type=='tc2muts':
            tc2mut1, tc2mut2, tc2mut3, tc2mut4, tc2mut5, tc2mut6 = res
            # out
            intersection = tc2mut1.keys() & tc2mut2.keys()
            inter_out = {key:len(tc2mut1[key]+tc2mut2[key]) for key in intersection}
            total_inter_out_len+=sum(list(inter_out.values()))

            bert_out_diff = tc2mut1.keys() - tc2mut2.keys()
            bert_out = {key:len(tc2mut1[key]) for key in bert_out_diff}
            total_bert_out_len += sum(list(bert_out.values()))

            fim_out_diff = tc2mut2.keys() - tc2mut1.keys()
            fim_out = {key: len(tc2mut2[key]) for key in fim_out_diff}
            total_fim_out_len += sum(list(fim_out.values()))

            # fit
            if tc2mut3 is None or tc2mut4 is None:
                pass
            else:
                intersection = tc2mut3.keys() & tc2mut4.keys()
                inter_fit = {key: len(tc2mut3[key] + tc2mut4[key]) for key in intersection}
                total_inter_fit_len += sum(list(inter_fit.values()))

                bert_fit_diff = tc2mut3.keys() - tc2mut4.keys()
                bert_fit = {key: len(tc2mut3[key]) for key in bert_fit_diff}
                total_bert_fit_len += sum(list(bert_fit.values()))

                fim_fit_diff = tc2mut4.keys() - tc2mut3.keys()
                fim_fit = {key: len(tc2mut4[key]) for key in fim_fit_diff}
                total_fim_fit_len += sum(list(fim_fit.values()))

            if tc2mut5 is None or tc2mut6 is None:
                pass
            else:
                intersection = tc2mut5.keys() & tc2mut6.keys()
                inter_req = {key: len(tc2mut5[key] + tc2mut6[key]) for key in intersection}
                total_inter_req_len += sum(list(inter_req.values()))

                bert_req_diff = tc2mut5.keys() - tc2mut6.keys()
                bert_req = {key: len(tc2mut5[key]) for key in bert_req_diff}
                total_bert_req_len += sum(list(bert_req.values()))

                fim_req_diff = tc2mut6.keys() - tc2mut5.keys()
                fim_req = {key: len(tc2mut6[key]) for key in fim_req_diff}
                total_fim_req_len += sum(list(fim_req.values()))

latex_table_output = ''
for k, v in total_out_res.items():
    latex_table_output += f'\\hline \n {k} & {v[0]} & {v[1]} \\\\ \n'

print('output:')
print(latex_table_output)

latex_table_fitness = ''
for k, v in total_fit_res.items():
    latex_table_fitness += f'\\hline \n {k} & {v[0]} & {v[1]} \\\\ \n'
print('fitness:')
print(latex_table_fitness)

latex_table_req = ''
for k, v in total_req_res.items():
    latex_table_req += f'\\hline \n {k} & {v[0]} & {v[1]} \\\\ \n'
print('req:')
print(latex_table_req)

# plot separately
# def plot(bert_only,fim_only, inter, type):
#
#     sizes = [bert_only,fim_only, inter]
#     labels = ['TSbert_only', 'TSFIM_only', 'TS_overlap']
#
#     # 绘制饼状图
#     colors = ['#5CB3FF', '#FFA500', '#90EE90']
#     plt.pie(sizes, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140,colors=colors)
#     plt.axis('equal')  # 确保饼状图是圆的
#     # plt.title(f'Test case overlap by {type}')
#     plt.legend(labels, loc="upper left")
#     plt.savefig(f'{type}_test_cases.png')
#     plt.close()
#
#
# output_overlap = plot(all_TS_bert_output, all_TS_FIM_output, all_TS_inter_output, 'output')
# fit_overlap = plot(all_TS_bert_fit, all_TS_FIM_fit, all_TS_inter_fit, 'fitness')
# req_overlap = plot(all_TS_bert_req, all_TS_FIM_req, all_TS_inter_req, 'requirement')



# plot output and req
# def plot(bert_only, fim_only, inter, caption, ax):
#     sizes = [bert_only, fim_only, inter]
#     colors = ['#5CB3FF', '#FFA500', '#90EE90']
#     # 绘制饼状图到指定的Axes对象ax
#     wedges, texts, autotexts = ax.pie(
#         sizes, autopct='%1.1f%%', startangle=140, textprops={'fontsize': 18}, colors=colors
#     )
#     for autotext in autotexts:
#         if '32.0' in autotext.get_text() or '38.7' in autotext.get_text():
#             autotext.set_verticalalignment('top')
#         # 或者使用下面这行代码，手动将其向下移动
#             x, y = autotext.get_position()
#             autotext.set_position((x, y - 0.1))
#     ax.axis('equal')  # 确保饼状图是圆的
#     ax.set_title(caption, loc='left', fontsize=16)  # 设置子图标题靠左
#
# # 创建一个figure和两个子图的Axes对象
# fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))
#
# # 绘制两个饼图到这两个Axes对象上
# plot(all_TS_bert_output, all_TS_FIM_output, all_TS_inter_output, '(a) Classical mutation testing', ax1)
# plot(all_TS_bert_req, all_TS_FIM_req, all_TS_inter_req, '(b) Requirement-based mutation testing', ax2)
#
# # 添加共享的图例
# fig.legend(['SimuBERT only', 'FIM only', 'Both SimuBERT and FIM'], loc='upper right', bbox_to_anchor=(1, 0.89), fontsize=12)
#
# # 保存整个figure为图片
# plt.savefig('test_cases_comparison.png')
# plt.close()


import matplotlib.pyplot as plt

# 修改代码：将三个饼状图绘制到一个图里并共享一个图例
def plot_combined(bert_output, fim_output, inter_output, bert_fit, fim_fit, inter_fit, bert_req, fim_req, inter_req):
    # 生成数据
    sizes1 = [bert_output, fim_output, inter_output]
    sizes2 = [bert_fit, fim_fit, inter_fit]
    sizes3 = [bert_req, fim_req, inter_req]

    labels = ['SimuBERT only', 'FIM only', 'Both SimuBERT and FIM']
    colors = ['#5CB3FF', '#FFA500', '#90EE90']

    fig, axs = plt.subplots(1, 3, figsize=(15, 5))

    # 绘制饼状图1
    axs[0].pie(sizes1, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[0].axis('equal')  # 确保饼状图是圆的
    axs[0].set_title('Classical mutation testing')

    # 绘制饼状图2
    axs[1].pie(sizes2, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[1].axis('equal')
    axs[1].set_title('Fitness-based mutation testing')

    # 绘制饼状图3
    axs[2].pie(sizes3, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[2].axis('equal')
    axs[2].set_title('Requirement-based mutation testing')

    # 添加共享图例
    fig.legend(labels, loc='upper center', ncol=3)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig('overlap_test_cases')
    plt.show()

# 示例数据
plot_combined(30, 40, 30, 35, 25, 40, 20, 50, 30)
