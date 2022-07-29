# NSCSCC-2022

## INFO

基本架构：顺序多发

## 分支说明

- `doc`：项目说明，统一`.gitignore`文件。
- `lyq_axi`：添加了需要的指令。
- `cyy_dev`：基于`lyq_axi`，系统测试开发。
- `wzy_dev`：基于`cyy_dev`，独立外设访问。
- `dev_lw`：基于`lyq_axi`优化了load to use的stall，同时将M的访存数据前推到D。
- `dev_occupy`：基于`lyq_axi`移除了fifo，并区分了F和D，利用occupy存放暂时无法双发的指令。
- `dev_cache`：基于`dev_lw`，只在E传递访存控制信号和数据，由D$自己流水生成M的信号，并在datapath的M阶段返回需要的数据；独立外设访问。

## TODO

- [x] 双发连接axi总线
- [ ] 分支预测
- [ ] 起操作系统
  - [ ] TLB
  - [ ] Cache对应的优化
  - [ ] MIPS架构的缓存一致性
  - [ ] 分Bank

