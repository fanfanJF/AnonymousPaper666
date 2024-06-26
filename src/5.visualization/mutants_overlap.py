import pandas as pd
import json

# 导入绘图库
import matplotlib.pyplot as plt


def analysis(model, mut, type):
    df = pd.read_csv(f'./{model}/TS{mut}_{type}.csv')
    total_num = len(df['killed'].tolist())
    num_killed = df['killed'].tolist().count(1)
    # print(f'{model}/TS{mut}_{type}:')
    # print(f'num_killed:{num_killed}, total_num:{total_num}')

    res = {}
    tcs = df['tests that killed'].tolist()
    names = df['mutant name'].tolist()
    for name, tc_ in zip(names, tcs):
        try:
            tc = tc_.split(',')
        except:
            continue
        tc = [int(item.split('_')[1]) for item in tc if item != '']
        for i in tc:
            if res.get(i):
                res[i].append(name)
            else:
                res[i] = [name]
    TS = set(sorted(list(res.keys())))

    return res, num_killed


def get_muts(key,dic):
    res_ = set()
    for k,v in dic.items():
        if int(k) in key:
            for item in v:
                res_.add(item)
    return res_



bert_output_only_muts = 0
FIM_output_only_muts = 0
output_inter_muts = 0

bert_fit_only_muts = 0
FIM_fit_only_muts = 0
fit_inter_muts = 0

bert_req_only_muts = 0
FIM_req_only_muts = 0
req_inter_muts = 0

for model in ['tustin','twotanks','fsm', 'ATCS']:
    tc2muts_bert_output, bert_output_killed_muts = analysis(model, 'bert', 'output')
    tc2muts_FIM_output, FIM_output_killed_muts = analysis(model, 'FIM', 'output')
    print('\n')

    tc2muts_bert_fit, bert_fit_killed_muts = analysis(model, 'bert', 'fitness')
    tc2muts_FIM_fit, FIM_fit_killed_muts = analysis(model, 'FIM', 'fitness')
    print('\n')
 
    if model not in ['fsm', 'AECS']:
        tc2muts_bert_req, bert_req_killed_muts = analysis(model, 'bert', 'req')
        tc2muts_FIM_req, FIM_req_killed_muts = analysis(model, 'FIM', 'req')
        print('\n')
    else:
        tc2muts_bert_req = {}
        tc2muts_FIM_req = {}
        bert_req_killed_muts=0
        FIM_req_killed_muts=0

    tsbert_output_only = set(tc2muts_bert_output.keys())-set(tc2muts_FIM_output.keys())
    tsFIM_output_only = set(tc2muts_FIM_output.keys())-set(tc2muts_bert_output.keys())
    ts_output_inter = set(tc2muts_FIM_output.keys())&set(tc2muts_bert_output.keys())
    if len(tsbert_output_only) != 0:
        bert_output_only_muts += len(get_muts(tsbert_output_only, tc2muts_bert_output))/bert_output_killed_muts
    if len(tsFIM_output_only) != 0:
        FIM_output_only_muts += len(get_muts(tsFIM_output_only, tc2muts_FIM_output))/FIM_output_killed_muts
    if len(ts_output_inter) != 0:
        output_inter_muts += len(get_muts(ts_output_inter, tc2muts_FIM_output))/((FIM_output_killed_muts+bert_output_killed_muts)/2)

    tsbert_fit_only = set(tc2muts_bert_fit.keys())-set(tc2muts_FIM_fit.keys())
    tsFIM_fit_only = set(tc2muts_FIM_fit.keys())-set(tc2muts_bert_fit.keys())
    ts_fit_inter = set(tc2muts_FIM_fit.keys())&set(tc2muts_bert_fit.keys())
    if len(tsbert_fit_only) != 0:
        bert_fit_only_muts += len(get_muts(tsbert_fit_only, tc2muts_bert_fit))/bert_fit_killed_muts
    if len(tsFIM_fit_only) != 0:
        FIM_fit_only_muts += len(get_muts(tsFIM_fit_only, tc2muts_FIM_fit))/FIM_fit_killed_muts
    if len(ts_fit_inter) != 0:
        fit_inter_muts += len(get_muts(ts_fit_inter, tc2muts_FIM_fit))/((FIM_fit_killed_muts+bert_fit_killed_muts)/2)

    tsbert_req_only = set(tc2muts_bert_req.keys())-set(tc2muts_FIM_req.keys())
    tsFIM_req_only = set(tc2muts_FIM_req.keys())-set(tc2muts_bert_req.keys())
    ts_req_inter = set(tc2muts_FIM_req.keys())&set(tc2muts_bert_req.keys())
    if len(tsbert_req_only) != 0:
        bert_req_only_muts += len(get_muts(tsbert_req_only, tc2muts_bert_req))/bert_req_killed_muts
    if len(tsFIM_req_only) != 0:
        FIM_req_only_muts += len(get_muts(tsFIM_req_only, tc2muts_FIM_req))/FIM_req_killed_muts
    if len(ts_req_inter) != 0:
        req_inter_muts += len(get_muts(ts_req_inter, tc2muts_FIM_req))/((FIM_req_killed_muts+bert_req_killed_muts)/2)




# def plot(bert_only,fim_only, inter, type):
#
#     sizes = [bert_only,fim_only, inter]
#     labels = ['TSbert_only_killed_muts', 'TSFIM_only_killed_muts', 'TSbertFIM_both_killed_muts']
#
#     colors = ['#5CB3FF', '#FFA500', '#90EE90']
#     plt.pie(sizes, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140,colors=colors)
#     plt.axis('equal')  # 确保饼状图是圆的
#     plt.legend(labels, loc="upper left")
#     plt.savefig(f'{type}_muts.png')
#     plt.close()
#
# plot(bert_output_only_muts,FIM_output_only_muts,output_inter_muts,'output')
# plot(bert_fit_only_muts,FIM_fit_only_muts,fit_inter_muts,'fitness')
# plot(bert_req_only_muts,FIM_req_only_muts,req_inter_muts,'requirement')
#


import matplotlib.pyplot as plt

def plot_combined(bert_output, fim_output, inter_output, bert_fit, fim_fit, inter_fit, bert_req, fim_req, inter_req):
    # 生成数据
    sizes1 = [bert_output, fim_output, inter_output]
    sizes2 = [bert_fit, fim_fit, inter_fit]
    sizes3 = [bert_req, fim_req, inter_req]

    labels = ['SimuBERT only', 'FIM only', 'Both SimuBERT and FIM']
    colors = ['#5CB3FF', '#FFA500', '#90EE90']

    fig, axs = plt.subplots(1, 3, figsize=(15, 5))  # 调整为需要的尺寸

    # 绘制饼状图1
    axs[0].pie(sizes1, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[0].axis('equal')
    axs[0].set_title('Mutants by classical mutation testing')

    # 绘制饼状图2
    axs[1].pie(sizes2, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[1].axis('equal')
    axs[1].set_title('Mutants by fitness-based mutation testing')

    # 绘制饼状图3
    axs[2].pie(sizes3, autopct='%1.1f%%', textprops={'fontsize': 18}, startangle=140, colors=colors)
    axs[2].axis('equal')
    axs[2].set_title('Mutants by requirement-based mutation testing')

    # 添加共享图例
    fig.legend(labels, loc='upper center', ncol=3)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(f'overlap_muts.png')
    plt.show()

# 示例数据
plot_combined(bert_output_only_muts, FIM_output_only_muts, output_inter_muts,
              bert_fit_only_muts, FIM_fit_only_muts, fit_inter_muts,
              bert_req_only_muts, FIM_req_only_muts, req_inter_muts)
