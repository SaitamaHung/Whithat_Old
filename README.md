# Whithat

[![License](https://img.shields.io/github/license/Theopse/Whithat)](https://choosealicense.com/licenses/bsd-2-clause/)
[![Build Status](https://travis-ci.org/Theopse/Whithat.svg?branch=Testing)](https://travis-ci.org/Theopse/Whithat)
[![GitHub repo size](https://img.shields.io/github/repo-size/Theopse/Whithat)](https://github.com/Theopse/Whithat/tree/Testing)

暂时是个B站视频下载器，使用了[Httpoison](https://github.com/edgurgel/httpoison)

未来考虑成为Elixir中[you-get](https://github.com/soimort/you-get)

不提供Sessdata，请自备

（旧版本因为疏忽附带Sessdata，如果实在需要可以自行提取，但不保证可用）

（新版本修复了Private API的使用问题，可以不需要Sessdata获取链接）

## 编译

- Erlang/otp >= 21
- Elixir >= 1.10

#### 通过Escript

```
mix deps.get
mix deps.compile
mix escript.build
mix escript.install
```

## 用法

```
whithat aid/bvid quality [pages]
```

Aid：B站的AV号，不需要带前缀

Bvid: B站的BV号，需要前缀

Quality: 视频画质。

- 120 -> 4K
- 116 -> 1080P60
- 112 -> 1080P+
- 80 -> 1080P
- 74 -> 720P60
- 64 -> 720P
- 48 -> 720P(MP4)
- 32 -> 480P
- 16 -> 360P
  
Pages: 多P视频的页码。

格式：1,2,3,4-6 -> [1,2,3,4,5,6]

事例： ```Whithat 19381096 64 1-2``` [视频地址](https://www.bilibili.com/video/av19381096)

请将Source/Config.ex中```def sessdata,do: "Put Your Sessdata Here"```后面的```"Put Your Sessdata Here"```替换成自己账号的Sessdata

## 目标

- 成为一个合格的库+应用
- 成为Elixir中的[you-get](https://github.com/soimort/you-get)

## 非目标

- 暂时不清楚/-/

## 目前问题

- 测试下来也没啥问题
- 魔改了Mix.exs（别打我QAQ）（我以后改回来还不行么QAQ）
- 部分地方直接使用以前不懂fp时的代码，很有命令式编程的风味（QaQ）
- 当初不知道Enum.with_index时搞的库依旧在源码里（
- 码风很诡异（没事反正能改（bushi）），我是一个坚定的tab党（Tab才是真正的道理！）
- Readme的用词很......风趣（确信）（如果不行的话那我还是严肃得了QAQ）

## 更新目标

- 支持[A站](https://www.acfun.cn)
- 重写main函数

## 下载

由于暂时没达到目标

请自行git clone吧（bushi）

## 关于其他

说是个组织，结果各种问题之后，还是只有我一个人/-/

行吧，一个人就一个人，这样也好（bushi）

大致读了一下you-get的代码，基本上懂了如何在python中写（废话），看看哪天翻译到Elixir里吧

不过这得先把main函数重写/-/