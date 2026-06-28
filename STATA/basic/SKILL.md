---
name: stata-basic
description: Stata基础Skill，涵盖数据预处理、清洗、特征工程及简单回归分析，遵循标准化项目结构与可复现性原则。
version: 1.4
---

# Stata 基础研究技能指南

> **Skill for**: 执行标准化的 Stata 数据处理与实证分析流程，确保研究过程的可复现性、文档化与专业性。

---

## 1. 核心运行原则

### 1.1 执行与日志
- **静默执行**：使用 `stata -e do DOFILE.do` 命令运行 Do-files。
- **日志记录**：所有 Do-files 必须包含完整的日志记录（`log using`），以便 Agent 和研究人员回溯。
- **静默中间过程**：计算的中间过程（如辅助变量的生成、临时数据操作等），如果结果本身并不重要，应使用 `quietly` 前缀关闭输出，以减少 log 文件长度，方便 AI 读取和分析关键结果。例如：
  ```stata
  quietly gen temp_var = x + y
  quietly su x, meanonly
  quietly drop temp_*
  ```
- **禁止静默捕获错误**：除非有明确的理由（如检查命令是否可用、处理已知的可能失败场景），否则**严禁**使用 `capture`（`cap`）前缀隐藏错误信息。错误提示是调试和确保代码正确性的关键线索，盲目捕获错误会导致问题被掩盖，增加排查难度。

### 1.2 项目目录结构
项目根目录下必须建立以下标准化文件夹：
- `Raw_data/`：存放原始数据文件。**严禁**直接修改或覆盖此目录下的文件。
- `Data/`：存放清洗过程及清洗后的 `.dta` 数据文件（由 Do-files 从 `Raw_data` 生成）。
- `Do-files/`：存放 Stata 脚本，按步骤编号（如 `S1_clean_data.do`, `S2_gen_var.do`）。
- `Results/`：存放导出的表格、图表等。

### 1.3 路径配置文件 (`S0_path_setting.do`)

每个项目必须创建 `S0_path_setting.do`，统一配置路径宏：

```stata
* S0_path_setting.do — 路径与全局配置
global ROOT "~/PATH/TO/ROOT"      // 替换为项目根目录的绝对路径
global RAW_DATA "$ROOT/Raw_data/"
global DATA     "$ROOT/Data/"
global RESULTS  "$ROOT/Results/"
cd $ROOT

* 统一输出格式偏好（供 AGENTS.md 记录）
* global TABLE_FORMAT "word"      // word | latex
* global GRAPH_FORMAT "png"       // png | pdf | eps
```

**规范**：
- **每个 Do-file 的第一行**必须是 `include "${ROOT}/Do-files/S0_path_setting.do"`。如果没有配置$ROOT，则使用相对路径 `include "Do-files/S0_path_setting.do"`。
- 所有后续文件操作（`use`, `save`, `export`）必须使用上述宏，禁止硬编码路径。
- 若用户未按标准结构组织文件，将其数据移入 `Raw_data/`（或接受 `raw_data`、`原始数据` 等用户自定义名称）。

### 1.4 可复现性
- **随机数种子**：所有涉及随机抽样、交叉验证、自助法（Bootstrap）或随机排序的操作，必须显式设置种子。设置方式有两种：
  1. **全局设置**：在 Do-file 开头使用 `set seed <number>`（如 `set seed 42`），影响后续所有随机命令。
  2. **命令选项**：部分命令支持通过选项直接设置种子，此时**不需要**也不应再使用 `set seed`：
     - `bootstrap, seed(42)`
     - `sdid y id year treat, vce(bootstrap) seed(42)`
     - 其他支持 `seed()` 选项的命令（如 `permute`、`simulate` 等）

### 1.5 文档化
- **AGENTS.md**：在项目初始化后创建/更新，记录文件夹结构、数据层级信息、用户偏好的导出格式等。
- **data_define.md**：在项目根目录记录每个变量的来源、处理步骤及描述性统计。

---

## 2. 数据清洗 (Data Cleaning)

### 2.1 原始数据导入
- **CSV/Excel**：
  1. 先使用 Python 脚本探索首行变量名。
  2. 使用 Stata `import` 命令导入并保存至 `Data/`。
  3. 若数值变量被识别为字符串，使用 Python 检查原因并修正，保存为**新文件**，严禁覆盖原始文件。
- **DTA 文件**：使用 `dta2md` 导出数据集元数据与描述性统计（**不占用内存**，通过临时 frame 读取）。帮助文件：`~/ado/plus/d/dta2md.sthlp`。

  **基本语法**：
  ```stata
  dta2md "filepath.dta" [using "outputfile.md"] [, options]
  ```

  **常用选项**：

  | 选项 | 说明 |
  |------|------|
  | `descriptive` | 输出每个变量的频数表与描述性统计（默认仅输出数据集概览和变量清单） |
  | `varlist(varlist)` | 仅导出指定变量，如 `varlist(age income gender)` |
  | `labeled` | 仅导出带有变量标签的变量（跳过无标签的临时/中间变量） |
  | `maxcat(#)` | 频数表的最大唯一值个数阈值，默认 `20`；超过则显示描述统计而非频数表 |
  | `maxfreq(#)` | 频数表的最大行数，默认 `30` |
  | `english` | 输出英文标题（默认中文） |

  **典型用法示例**：
  ```stata
  * 基本用法：导出概览+变量清单，输出到同目录的 mydata_metadata.md
  dta2md "Raw_data/survey2024.dta"

  * 导出详细统计（含频数表和描述统计），阈值为 50 个唯一值
  dta2md "Raw_data/survey2024.dta", descriptive maxcat(50)

  * 指定输出路径，仅导出 labeled 变量，使用英文标题
  dta2md "Raw_data/survey2024.dta" using "Data/survey_meta.md", descriptive labeled english

  * 仅导出关注的变量
  dta2md "Raw_data/survey2024.dta", varlist(age income education) descriptive
  ```

  **输出内容**：
  1. **数据集概览**：观测值数、变量数、面板/时间序列结构（若已 `xtset`/`tsset`）
  2. **变量清单**：变量名、存储类型、变量标签
  3. **变量详情**（需加 `descriptive`）：
     - 带标签数值变量（唯一值 ≤ `maxcat`）：频数表（数值、值标签、计数、百分比）
     - 无标签数值变量或唯一值较多：N、均值、标准差、最小值、最大值
     - 字符串变量（唯一值 ≤ `maxcat`）：频数表
     - 字符串变量（唯一值较多）：唯一值计数和缺失值计数

  **替代方案：`describe` 命令（Stata 官方命令）**

  如果 `dta2md` 不可用或需要更轻量的描述，可使用 Stata 内置的 `describe` 命令。关键是**必须将结果保存为 Markdown 文件**，以便后续步骤中 Agent 可以直接读取。

  ```stata
  * 方法1：使用 describe 命令并手动保存结果
  describe using "Raw_data/survey2024.dta", clear
  describe
  * 将输出复制到 survey2024.md 文件中

  * 方法2：使用 log 文件捕获 describe 输出，然后转换为 markdown
  log using "Raw_data/survey2024_describe.txt", text replace
  describe using "Raw_data/survey2024.dta", clear
  describe
  summarize
  log close
  * 手动或脚本转换为 survey2024.md
  ```

  **变量描述文件命名规范**：
  - 对于每个 `.dta` 文件，首先检查同目录下是否存在**同名**的 `.md` 文件（如 `survey2024.dta` 对应 `survey2024.md`）。
  - 如果存在，直接读取该 `.md` 文件了解数据结构。
  - 如果不存在，使用 `dta2md` 生成描述文件，或使用 `describe` 命令并保存为同名 `.md` 文件。
  - **严禁仅使用 `describe` 查看而不保存**，因为后续步骤中 Agent 无法直接读取临时的命令输出。

- **问卷数据**：若包含 PDF 问卷，使用 `marker-pdf` 转换为 Markdown 以读取变量定义。

### 2.2 数据结构识别
必须在 `AGENTS.md` 中记录以下信息：
- **数据类型**：截面数据、面板数据或时间序列？
- **ID 层级**：最细颗粒度的 ID 是什么（国家、省、市、行业、公司、家庭、个人）？
- **时间维度**：频率（年度、季度、月度等）？
- **跨表一致性**：不同文件的 ID 是否一致（使用 `tab` 检查）？
- **面板设置**：若是面板数据，使用 `xtset` 设定结构并检查错误。

### 2.3 数据合并
- **多年数据合并**：
  - **宽面板**：标准化变量名后导入，使用 `reshape long`。
  - **年度分表**：标准化变量名，生成年度变量后使用 `append`。
- **多层级合并**：
  - 以微观数据（如企业）为母表（Master），匹配宏观数据（如城市、行业）。
  - 使用 `merge` 并严格检查 `_merge == 3` 的比例。

### 2.4 缺失值处理

- **默认禁止简单填充**：如果没有特别的理由，**严禁**使用 0、均值、中位数或其他单一数值对缺失值进行填充。简单填充会扭曲变量分布、低估标准误，并可能引入系统性偏差。
- **先诊断，再处理**：
  - 使用 `misstable summarize` 或 `mdesc`（若可用）检查每个变量的缺失比例和缺失模式。
  - 区分缺失类型：完全随机缺失（MCAR）、随机缺失（MAR）和非随机缺失（MNAR）。
- **必须提示用户的情形**：
  - 某个变量的缺失值比例过高（如超过 20%）。
  - 变量出现逻辑异常值（如收入为负数、年龄超过合理范围）。
  - 缺失模式可能与非观测因素相关（如高收入群体不愿报告收入）。
- **有问卷或变量说明时**：
  - 可以先按照问卷设计、变量说明以及统计上合理的方法处理（例如：问卷中明确跳答导致的缺失可编码为系统缺失；某些变量有官方插值方法）。
  - **但必须将处理方法明确告知用户**，说明为何如此处理以及可能带来的影响。
- **推荐处理方式**：
  - 优先使用完整案例分析（listwise deletion）或多重插补（multiple imputation）等统计方法。
  - 若必须使用单一值填充，必须记录理由并在 `data_define.md` 中详细说明。

---

## 3. 特征工程 (Feature Engineering)

### 3.1 变量分类处理

#### 定性变量
字符串类型的定性数据需使用 `egen VAR_id = group(VAR)` 进行数值编码。

#### 定量变量 —— 对数转换
取对数不仅适用于规模变量，核心判断标准是：**变动"1%"是否比变动"1单位"更符合直觉**。

| 变量类型 | 示例 | 是否取对数 | 理由 |
|---------|------|-----------|------|
| 规模类 | 收入、消费、GDP、资产规模 | **是** | 通常关注百分比变动 |
| 价格类 | 房价、股价、汇率 | **是** | 百分比变动更符合直觉 |
| 物理量 | 身高、体重、温度 | **否** | "1cm"、"1kg"的变动更直观 |
| 评分/指数 | 考试分数、满意度评分 | **否** | "1分"的变动更直观 |
| 百分比 | 失业率、增长率 | **否** | 本身已是百分比 |

**操作规范**：
```stata
* 取对数前检查0值和负值
tab x if x <= 0

* 常规对数转换
gen log_x = ln(x)

* 取对数后缺失值处理（若缺失值 > 10%）
* 方案A：log(1+x)（批评较多但常见）
gen log_x = ln(1 + x)

* 方案B：若 x 为解释变量，补0 + 缺失指示变量
gen log_x = ln(x)
replace log_x = 0 if log_x == .
gen d_x = log_x == .
* 回归时同时使用 log_x 和 d_x

* 方案C：若 x 为被解释变量且大量0值，使用 ppmlhdfe
ppmlhdfe y x controls, absorb(FEs) cluster(CLs)
```

#### 中心化操作（连续变量）
对连续变量构造平方项、高阶项或交乘项时，必须先**中心化**（去均值），以减轻多重共线性并提高系数可解释性。

```stata
* 中心化示例
su x1, meanonly
gen demean_x1 = x1 - r(mean)
gen x1_sq = demean_x1^2
gen x1_x2 = demean_x1 * demean_x2
```

**注意**：虚拟变量（0/1）**不需要**中心化。

#### 零值处理
若变量有大量 0 值，生成零值哑变量：
```stata
gen d_x = x == 0 if x != .
```

### 3.2 哑变量生成规范
- **严禁**：`gen d_x = x > 0`（会误将缺失值设为 1）。
- **正确**：`gen d_x = x > 0 if x != .`。

### 3.3 文档化
特征工程结束后，将每个变量的生成情况、具体操作理由及描述性统计（样本量、均值、标准差、最小值、最大值）写入 `data_define.md`。

---

## 4. 实证回归分析 (Regression Analysis)

> **⚠️ 重要适用范围声明**：本节（第4节"实证回归分析"）中的所有内容——包括控制变量选择、模型设定、标准误计算、结果汇报等——**仅适用于**经济学中以**因果推断**为目的的实证分析，即研究者关注的是核心解释变量（treatment variable）系数的**因果解释**（causal interpretation）。
>
> **本节规范不适用于：**
> - **一般统计分析**：如描述性统计、相关性分析、数据探索等
> - **预测问题**：如机器学习预测、时间序列预测、商业智能分析、信用评分模型等
> - **非因果研究**：如纯相关性分析、探索性因子分析、降维等
> - 任何不以"核心解释变量系数的因果解释"为最终目的的研究
>
> 在以上非因果场景中，回归模型的选择标准、控制变量的选取逻辑、固定效应的设置原则、标准误的计算方法等可能**完全不同**。例如，在预测问题上，变量选择应以预测精度为导向而非因果排除；在一般统计分析中，多重共线性的处理方式也会有所不同。

### 4.1 控制变量选择 —— 避免坏控制 (Bad Control)

控制变量的选取必须遵循因果逻辑，避免引入**坏控制变量**（即核心解释变量的结果变量）。

**选择流程**：
1. **初筛**：列出所有可能是**被解释变量原因**的变量，以及所有**可能影响核心解释变量**的变量。
2. **因果判断**：逐一判断每个潜在控制变量是否可能是**核心解释变量的结果**。如果是，则**剔除**；如果是核心解释变量的**原因**，则**保留**。

**示例**：
- 研究教育（x）对收入（y）的影响。
- 职业类型可能是教育的结果（教育是职业的原因），因此职业类型是**坏控制**，应剔除。
- 家庭背景影响教育获得，是核心解释变量的原因，可以保留。

### 4.2 回归模型选择

#### 截面数据
使用 `reghdfe`：
```stata
reghdfe y x controls, absorb(FEs) cluster(CLs)
```
- `absorb(FEs)`：遵循"尽可能细致"原则设置固定效应（如能控制城市就不控制省份）。
- `cluster(CLs)`：聚类稳健标准误，级别不低于核心解释变量级别（如省份层面政策至少聚类到省份）。

#### 面板数据
**严禁使用随机效应（RE）**，必须使用固定效应（FE）：
```stata
xtset id year
reghdfe y x controls, absorb(id year) cluster(id)
```
- 必须同时包含个体固定效应和时间固定效应。
- 标准误必须至少在个体层面聚类。
- 允许添加交互固定效应，如 `absorb(id year i.prov#i.year)`。

### 4.3 局部宏规范

使用局部宏统一管理模型设定，便于后续修改和复现：

```stata
* 定义局部宏
local Controls "c1 c2 c3 c4"
local FEs      "city year"
local CLse     "city"

* 截面数据回归
reghdfe y x `Controls', absorb(`FEs') cluster(`CLse')

* 面板数据回归
reghdfe y x `Controls', absorb(id year `FEs') cluster(id)
```

**优势**：
- 修改控制变量只需改动一处 `local Controls`。
- 固定效应和聚类层级集中管理，避免遗漏。

### 4.4 内生性处理策略
- **弱内生性**：使用当期值。
- **强内生性**：可考虑使用一阶滞后项（`L.x`）缓解这一问题。
- **初始值趋势控制**：使用 `gen_init_var` 生成每个个体的基期变量值，再与时间固定效应交互以控制初始条件差异。

  **基本语法**：
  ```stata
  gen_init_var varname, yearvar(varname) year(value) by(varname) generate(newvar) [stringyear]
  ```

  **必需选项**：

  | 选项 | 说明 |
  |------|------|
  | `yearvar(varname)` | 时间变量（如 `year`） |
  | `year(value)` | 基期年份（数值，如 `2000`） |
  | `by(varname)` | 面板标识变量（如 `firmid`、`household_id`） |
  | `generate(newvar)` | 生成的新变量名 |

  **可选选项**：

  | 选项 | 说明 |
  |------|------|
  | `stringyear` | 时间变量为字符串类型时使用（如 `year("2010")`） |

  **典型用法示例**：
  ```stata
  * 例1：生成企业2000年的初始销售额，并用于回归控制
  gen_init_var sales, yearvar(year) year(2000) by(firmid) generate(sales0)
  reghdfe y x controls, absorb(id year i.year#c.sales0) cluster(id)

  * 例2：时间变量为字符串时的写法
  gen_init_var revenue, yearvar(period) year(2010) by(id) generate(rev_init) stringyear
  ```

  **注意事项**：
  - 命令使用临时 frame 读取数据，**不干扰当前内存中的数据集**。
  - 若同一面板单位在基期有多条观测，取**最小值**广播；如有需要请预先筛选。
  - 若基期无观测或输出变量名已存在，命令会报错。
  - 帮助文件：`~/ado/plus/g/gen_init_var.sthlp`

### 4.5 结果导出
- 使用 `outreg2` 或 `estout` 导出结果。
- 默认导出 Word 格式，除非用户指定 LaTeX。

### 4.6 回归结果汇报规范

- **默认汇报标准误**：所有回归结果表格必须汇报**系数下方的标准误**（standard errors），而非 t 值或 p 值。
- **标准误格式**：
  - 使用聚类稳健标准误时，在表格注释中注明聚类层级，例如："Robust standard errors clustered at the firm level in parentheses."。
  - 使用异方差稳健标准误时，注明："Robust standard errors in parentheses."。
- **显著性标记**：若需要标注显著性水平，统一使用 `* p < 0.1, ** p < 0.05, *** p < 0.01`，并在表格底部说明。
- **导出工具设置**：
  - 使用 `outreg2` 时，通过选项控制输出格式，确保输出标准误而非 t 值/p 值。
  - 使用 `estout` 时，明确指定 `cells(b(star fmt(3)) se(par fmt(3)))` 等选项以输出系数与标准误。

### 4.7 机制分析（Mechanism Analysis）—— 严禁三段法

#### 核心原则

**严禁使用 Baron & Kenny (1986) 的中介效应三段法（三步法）进行机制分析。** 该方法的逐步检验逻辑（X→Y 显著 → X→M 显著 → M→Y 显著且 X→Y 减弱）在计量经济学中已被广泛批评，主要问题包括：

- **遗漏变量偏误**：M→Y 的回归几乎必然遗漏影响 Y 的其他因素，导致中介效应估计系统性有偏。
- **"部分中介"的统计检验力不足**：Sobel 检验和 Bootstrap 检验在小样本或弱效应下表现不佳。
- **反向因果混淆**：三步法无法区分 M 是真正的机制变量还是仅与 Y 共变。
- **强假设不可检验**：三步法隐含假设 M 与误差项不相关（sequential ignorability），这一假设在绝大多数应用场景下不成立。

#### 正确的机制分析思路

机制分析的正确思路是：

1. **找到中介变量 M**：该变量应当在理论上天然地对被解释变量 Y 有影响（由经济学理论、先验文献或制度背景支撑），而非纯粹由数据挖掘得到。
2. **验证 X 对 M 的影响**：仅需验证核心解释变量 X 对中介变量 M 是否有显著且符合预期方向的影响。**不需要**再回归 M→Y 或检验 X 的系数是否下降。
3. **逻辑链条**：如果 M 天然影响 Y（理论保证），且 X 影响 M（实证验证），则「X → M → Y」的机制即被确立。

#### 代码示例

```stata
* 正确：机制分析只需检验 X → M
* 设定 M 为中介变量（如企业创新投入 ln_invpat，天然影响 TFP）
local M "ln_invpat"

* 直接检验核心解释变量对中介变量的影响
reghdfe `M' did `Controls', absorb(firm year) vce(cluster city)

* 如果 did 系数显著且符号与理论一致，则机制成立
* 到此为止，不需要再做 M → Y 的回归
```

```stata
* 错误：严禁使用的 Baron-Kenny 三段法
* reghdfe y did controls, absorb(fe)           // Step 1: X → Y
* reghdfe m did controls, absorb(fe)           // Step 2: X → M
* reghdfe y did m controls, absorb(fe)         // Step 3: X + M → Y
* * 如果 Step 3 中 did 系数下降 → 声称存在"中介效应"
* * ❌ 这种做法在计量经济学中不被接受
```

#### 替代方法（若必须量化机制贡献）

若确实需要量化机制渠道的相对重要性，可考虑：

| 方法 | 说明 |
|------|------|
| **简约式（Reduced-form）对比** | 分别以 Y 和 M 作为被解释变量回归，比较 X 的系数符号和显著性 |
| **工具变量法** | 若 M 存在内生性，使用 IV 估计 M→Y 的关系（但需有效工具变量） |
| **结构方程模型** | 在强理论假设下使用 SEM，但需明确声明假设并进行敏感性分析 |

#### 关键引用

- 江艇 (2022). "因果推断经验研究中的中介效应与调节效应"，《中国工业经济》— 中文语境下的权威批评。

---

## 5. 故障排除与求助
- **未知命令**：在 `~/ado/plus/` 下按首字母路径查找帮助文件。
- **路径示例**：`help <cmd>` 对应 `~/ado/plus/f/f%%.sthlp`（其中 `f` 为首字母）。

---

## 6. 质量检查清单 (Quality Checklist)
- [ ] 原始数据是否已移动至 `Raw_data`？
- [ ] `S0_path_setting.do` 是否已配置并在所有 Do-file 中引用？
- [ ] 是否所有数据生成过程都在 `data_define.md` 中记录？
- [ ] 连续变量的平方/交乘项是否经过了中心化？
- [ ] 控制变量是否排除了坏控制（核心解释变量的结果变量）？
- [ ] 是否设置了 `seed`？
- [ ] 面板数据是否通过了 `xtset` 检查？
- [ ] 回归是否包含了必要的固定效应和聚类标准误？
- [ ] 是否使用局部宏统一管理了 Controls / FEs / Cluster？
- [ ] 导出表格是否包含了完整的变量标签和统计量？
- [ ] 回归结果表格是否汇报标准误（而非 t 值或 p 值）？
- [ ] 缺失值是否按照规范处理，未擅自使用 0 / 均值 / 中位数等简单填充？
- [ ] 机制分析是否仅验证了 X→M，**未使用** Baron-Kenny 三段法？
