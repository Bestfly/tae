api地址:http://proxy.cloudavh.com/api

必填查询参数：
1、TradeID（支付后产生的订单号，如：647444888778386）

可选查询参数：
2、limit（提取的代理ip数量，如：10，如果不填则返回剩余ip数量）
3、line（提取的代理ip类型，如果不填则为全部）
//1 电信, 2 联通, 3 移动, 4 教育, 5 长宽, 9 国外
4、repeat（是否过滤当天提取过的代理ip，默认为0即如果不填则为不过滤）
//1 过滤, 0 不过滤
5、country（指定查询某个国家的代理ip，如果不填则为全部）
//国家二字码，如CN（不区分大小写）

注意当country与line冲突时，系统优先以line为准。


api使用示例
一、提取100个代理ip
http://proxy.cloudavh.com/api?TradeID=647444888778386&limit=100

二、查询剩余ip数量
http://proxy.cloudavh.com/api?TradeID=647444888778386

三、提取国外代理ip100个，并过滤当天提取过的
http://proxy.cloudavh.com/api?TradeID=647444888778386&line=9&limit=100&repeat=1

四、提取美国代理ip100个
http://proxy.cloudavh.com/api?TradeID=647444888778386&country=us&limit=100

五、当country与line冲突时，系统优先以line为准
http://proxy.cloudavh.com/api?TradeID=647444888778386&country=us&line=2&limit=100

六、如果遗忘limit，仅返回剩余代理ip数量，其它参数不再起作用
http://proxy.cloudavh.com/api?TradeID=647444888778386&country=jp&line=9&repeat=1