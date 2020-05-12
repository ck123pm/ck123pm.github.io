title: JSON数据自动生成C++结构体
tags:
  - python
  - json
  - c++
categories: 编程
date: 2019-04-05 22:16:50
---
> 生成的c++结构体基于nlohmann/json进行解析，实现了类似JavaBean和C#中`JsonConvert.SerializeObject`的效果，将c++结构体与Json数据结构进行了映射，使得json解析成c++对象这一过程对上层屏蔽，可以实现快速开发。

<!--more-->

## 背景
在编写服务端程序时，除了和系统交互、业务逻辑的内部实现，最主要的一部分就是和客户端打交道。现在web服务器开发，最流行的数据传输格式基本是Json、Xml、Protobuf，其中Json格式由于其和javascript语言对象模型的兼容性最好，成为b/s模型下最常用的数据传输格式。

在高级语言如Java、C#中，有一些内置的库实现了语言对象模型和Json数据间的自动转换，这一点着实让cpper羡慕不已。虽然c++也有一些成熟的开源解析库如`nlohmann/json`、`RapidJson`、`Jsoncpp`等，让解析Json已经变得相对简单高效，但让程序员手动根据字段进行逐一解析仍然是一件比较浪费时间的事情。在性能要求没那么高的场景下（绝大多数情况），如果能实现c++对象和Json数据的自动转换，无疑能大幅提高开发效率，并减少因程序员手误导致的解析错误。

因此，考虑基于nlohmann/json解析库，实现c++和Json数据的对象映射自动代码生成。

## nlohmann/json基础
[nlohmann/json](https://github.com/nlohmann/json)是基于c++11特性实现的一个开源Json解析库，其在github上的start数达到了13.4k，开源协议为**MIT license**, 因此可以作为商用项目使用。整个解析库只有一个`json.hpp`，可以非常方便的移植到项目程序中。且解析库提供的接口非常人性化，上手容易，学习成本较低。
而对象映射这一功能，nolhmann库其实已经替我们实现了，举官方的一个例子说明：
```c++
namespace ns {
    // a simple struct to model a person
    struct person {
        std::string name;
        std::string address;
        int age;
    };
}

// create a person
ns::person p {"Ned Flanders", "744 Evergreen Terrace", 60};

// conversion: person -> json
json j = p;

std::cout << j << std::endl;
// {"address":"744 Evergreen Terrace","age":60,"name":"Ned Flanders"}

// conversion: json -> person
auto p2 = j.get<ns::person>();

// that's it
assert(p == p2);
};
```
可以看到，程序当中，我们只需要定义好一个`Person`结构体，再定义一个`json`对象，两者即可用`=`进行隐式转换。当然，实现隐式转换的前提是定义相应的`to_json`和`from_json`函数，该例中：
```c++
using nlohmann::json;

namespace ns {
    void to_json(json& j, const person& p) {
        j = json{{"name", p.name}, {"address", p.address}, {"age", p.age}};
    }

    void from_json(const json& j, person& p) {
        j.at("name").get_to(p.name);
        j.at("address").get_to(p.address);
        j.at("age").get_to(p.age);
    }
} // namespace ns
```

如上，我们得出基于nlohmann/json实现对象映射的核心步骤：
1. 定义一个c++结构体
2. 编写该c++结构体转换为json对象的`to_json`函数
3. 编写json对象转换为该c++结构体的`from_json`函数

## Python自动生成C++代码
如上介绍，对于一个现有的JSON数据，我们还是需要编写上述机械化的代码，这些完全可以找出格式上的规则使用Python进行自动化代码生成。在github上搜索了相关项目后，最终参考了一个项目的实现思路，使生成的代码采用nlohmman/json进行解析。
> 注: 原项目生成的代码使用的JSON库是`<cppRest/json.h>`，项目链接[kcris/json2cpp](https://github.com/kcris/json2cpp/blob/master/json2cpp.py)。

具体的生成代码不做详述，后面会将源码Po上，有兴趣的可以看一下。基本思想就是根据Json字段名进行类型区分，对于对象类型进行递归生成。最终的生成结果采用一个Object对象类型对应一个.h头文件和.cpp文件的形式。

## C++解析、组装函数封装（可选）
nlohmann库的隐式解析会抛出异常，我们需要捕获异常并进行相应处理。因此，在cpp中考虑对这部分进行了二次封装，使外层调用者不需要关心异常处理。此外，通信层传输的JSON格式有些是不带外层节点的，有些是带外层节点的，我们也需要对这两种格式做适配。
> 这部分有需要可以自己写一下，没有太多工作量。也可以参考我写好的，具体见最下方github链接。


-----------

## 快速开始
### 生成cpp文件
为了方便使用，基于tkinter做了一个界面，打包成了一个EXE工具。目前该工具只支持包含外层节点的JSON数据格式。
1. 打开Json2cppTool.exe
2. 填入JSON数据或者选择JSON数据文件
3. 选择输出路径
4. 点击生成

JSON数据如下：
```json
{
    "UserInfoDetail": {
        "mode": "",
        "EmployeeNoList": [
            {
                "employeeNo": ""
            }
        ]
    }
}

```
   
![json2cpp.png](https://camo.githubusercontent.com/f3c31b09611641f8dd072eca0f6e84bbc36d42a1/68747470733a2f2f75706c6f61642d696d616765732e6a69616e7368752e696f2f75706c6f61645f696d616765732f31343733353435342d353439633364636165636662656338622e706e673f696d6167654d6f6772322f6175746f2d6f7269656e742f7374726970253743696d61676556696577322f322f772f31323430)


### 文件导入工程
生成文件如下:
```
UserInfoDetail.h
UserInfoDetail.cpp
EmployeeNoList.h
EmployeeNoList.cpp
```

### C++程序中使用
**序列化**
```c++
UserInfoDetail user_info_detail ;
user_info_detail.m_mode = "all";
string str_json = JsonSerialize(user_info_detail);
```
**反序列化**
```
ResponseStatus response_status;
if (!JsonDeserialize(str_raw, response_status))
{
    return false;
}
```
That's it!
> 对于列表`std::list<T>`类型的节点，我们也无需做特殊处理，`nlohmann`已经将列表和`JSON Array`间的转换实现掉了。

### 进阶用法
#### 序列化时控制是否输出外层节点
默认会输出外层节点，但是可以通过JsonSerialize(Obj,**false**)来指定不生成外层节点。

示例：
```c++
string str_json = JsonSerialize(user_info_detail, false);
```
输出的JSON：
```json
{ 
    "mode": "",
    "EmployeeNoList": [
        {
            "employeeNo": ""
        }
    ]
}
```

#### 指定组装的节点
在默认情况下，自动映射会将c++结构体中的所有成员均映射到JSON中的节点。

但有的场景，我们希望发送给客户端或服务端的JSON数据中，只包含部分必填字段。
自动生成的c++结构体中包含了一个`std::set<std::string> m_visibleSet;`成员，通过该成员控制需要输出的节点。

示例：
```c++
UserInfoDetail user_info_detail ;
user_info_detail.m_mode = "all";
user_info_detail.m_visibleSet = {
    "mode",
};
string str_json = JsonSerialize(clearCfg);
```
输出的JSON：
```json
{
    "UserInfoDetail": {
        "mode": "all"
    }
}
```

#### 指定需要忽略的节点
在默认情况下，自动映射会将c++结构体中的所有成员均映射到JSON中的节点。

但有的场景，我们希望发送给客户端或服务端的JSON数据中，能忽略某些节点。
自动生成的c++结构体中包含了一个`std::set<std::string> m_hiddenSet;`成员，通过该成员控制需要忽略的节点。

示例：
```c++
UserInfoDetail user_info_detail ;
user_info_detail.m_mode = "all";
user_info_detail.m_hiddenSet = {
    "EmployeeNoList",
};
string str_json = JsonSerialize(clearCfg);
```
输出的JSON：
```json
{
    "UserInfoDetail": {
        "mode": "all"
    }
}
```
## 附录
源码见[json2cppTool](https://github.com/ck123pm/json2cppTool)