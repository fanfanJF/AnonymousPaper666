run('tc_test_bert_fitness.m')
run('tc_test_FIM_fitness.m')
run('tc_test_bert_output.m')
run('tc_test_FIM_output.m')
run('tc_test_bert_req.m')
run('tc_test_FIM_req.m')


run("tcbert_kill_fim_by_fit_diff.m")
run("tcbert_kill_fim_by_output.m")
run("tcbert_kill_fim_by_req.m")
run('tcFIM_kill_bert_by_fit_diff.m')
run('tcFIM_kill_bert_by_output.m')
run('tcFIM_kill_bert_by_req.m')