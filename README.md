
# Gatlingを使って負荷試験をしている話

負荷試験は大事なのは皆さんご存知だと思いますが
すぐにセットアップ出来る負荷試験ツールもあると良いですね。
この記事では、自分がやっている負荷試験の方法を紹介しておきます。
負荷試験にはGatlingを使っています。

この記事は以下の流れで説明していきます。

* Gatlingを動かす環境についての概要
* 負荷試験のシミュレーションをビルドしてパッケージしてから使っている
* Gatlingの設定をいい感じにするために、Typesafe Configを使っている
* まとめ

## 負荷環境について

現在はGatlingはAWSで動かすアプリケーションに負荷を掛けるために使っています。
また、Kinesisを使ったミドルウェアの負荷試験のセットアップなどにも使っています。

ざっくりした図です。

PackerでカーネルパラメータやJavaのインストール、unboundのインストールなどをやっています。
また、負荷試験をパッケージしたデータもこのタイミングでAMIに入れています。
今は割と頻繁に負荷試験を書き換えて実行することが多いので、このタイミングで入れなくても良いかなぁと思ったりしています。

Terraformでは、Packerで作ったAMIを元に
Autoscaling Groupを使って負荷を掛けるEC2を起動しています。
Autoscaling Groupを使ってEC2を立てる理由としては、EC2が1台では負荷が掛けられない時に
楽に負荷を増やしたいときに使います。

Ansibleは、負荷試験で使うファイルをコピーするために使っています。

ツールが３種類も出てきて整理したい気持ちは少しあるんですが
色々弄ってこの形に落ち着いています。

負荷試験のセットアップ周りについては直せそうかなぁと思っているのは以下の点です。

* PackerでJavaをインストールしているのをAnsibleに移して依存関係を明確にしたい
* Spotインスタンスを使うことで料金を減らしたい

どんどん良くしていきたいですね。

## 負荷試験のシミュレーションをビルドしてパッケージしてから使っている

タイトル通りなんですが、負荷試験のシミュレーションをビルドしてパッケージしてから使っています。
理由としてはざっくり以下の２つです。

1. 先にビルドしておくと、エラーもなく何事も無かったかのようにコンパイルが終了し、負荷試験が見つからない、というエラーを吐く状態が回避できる
2. 負荷試験のセットアップで外部のライブラリを使いたくなった時に楽

1の「先にビルドしておくと、エラーもなく何事も無かったかのようにコンパイルが終了し、負荷試験が見つからない、というエラーを吐く状態が回避できる」について説明します。
Gatlingでは、simulation-folderなどに負荷試験のScalaコードを配置することで
コンパイルした後、負荷試験として動かす機能があります。

このScalaをコンパイルするのはZincと呼ばれるコンパイラだそうなのですが
負荷試験で使う共通クラスを使うと、何もエラーが出力されずに
負荷試験が見つからない、といったエラーを吐いて
負荷試験のコンパイルに失敗する例に遭遇しました。

2の「負荷試験のセットアップで外部のライブラリを使いたくなった時に楽」について説明します。
今回自分たちが作っているアプリケーションはAWSの上で動いており、S3やSQS、Kinesisなどを使っています。
ある負荷試験のシナリオで、AWS SDKを使って負荷試験の前処理をやる必要が発生しました。
zipになっている Gatling を使う場合、library を置くフォルダに自分でコピーする必要があります。
しかし、この場合、依存関係をしっかり把握していないと、何をコピーするのか分からず、大変です。
推移依存がある場合などを考えた時に、手元でパッケージングするのが正解だと思いました。

そのため、sbt-packを利用して負荷試験のシナリオ群をパッケージして使っています。
sbt-packでは、ライブラリとその起動用のシェルに加えて、依存関係をtarget配下に纏めてくれる機能があります

以下のような設定を書いておくと、
JVM_OPTIONSを設定しつつ、起動クラスを指定した起動用のシェルが生成されます。

```sbt
enablePlugins(GatlingPlugin)
enablePlugins(PackPlugin)

// 省略

packMain := Map("gatling" -> "io.gatling.app.Gatling")
// gatlingの起動シェルをベースに設定している
packJvmOpts := Map("gatling" -> Seq(
  "-Xms2G", "-Xmx2G",
  "-XX:+UseG1GC",

  "-verbose:gc", "-XX:+PrintGCDetails", "-XX:+PrintGCDateStamps",
  "-Xloggc:gclog/gc_%t_%p.log",
  "-XX:+HeapDumpOnOutOfMemoryError",
  "-XX:+ExitOnOutOfMemoryError",
  "-XX:HeapDumpPath=heapdump/",
  "-XX:ErrorFile=error/",
  "-XX:+UseGCLogFileRotation",
  "-XX:NumberOfGCLogFiles=10",
  "-XX:GCLogFileSize=100M",

  "-XX:InitiatingHeapOccupancyPercent=75",
  "-XX:+ParallelRefProcEnabled",
  "-XX:+PerfDisableSharedMem",
  "-XX:+AggressiveOpts",
  "-XX:+OptimizeStringConcat",
  "-XX:+HeapDumpOnOutOfMemoryError",
  "-Dsun.net.inetaddr.ttl=60",
  "-Djava.net.preferIPv4Stack=true",
  "-Djava.net.preferIPv6Addresses=false"))
```

こんな感じで現在はsbt-packで負荷試験をパッケージングしています。

もうちょっと改善出来るなぁと思う点としては以下の点です。

* ローカルでビルドしているのを、CIでコミットごとにビルドして、負荷試験をS3などにリリースする
* 負荷試験を利用するときは、S3からインストールする

上記内容を適用すると、ローカルでちょこっと弄ってすぐに負荷掛けたい、といった要求には答えられません。
しかし、現在は自動で負荷テストをする、みたいなことはやっていないので
今の状態でも良いとは思っています。

## Gatlingの設定をいい感じにするために、Typesafe Configを使っている

負荷試験をやっている時に柔軟に設定を弄って負荷を掛けたい時があります。
例えば実行時間やユーザ数、あるいは環境のエンドポイント名など色々あります。
そのため、設定ファイルのフォーマットにTypesafe Configを採用しました。

採用した理由としては以下のものです。

* 人間が読みやすい期間の指定が出来るので、負荷を掛ける時間の設定が楽
* 変数の参照が出来る
* 構造化した形で設定を記述できる

```ini
# 人間が読みやすい期間の指定ができる
duration = 1hours
# 変数の参照が出来る
foo.endpoint = "https://foo."${env}".example.com"

env = "test"

# 構造化した形で設定を書ける
oauth {
  AccessTokenSimulation {
    duration = 1minutes
  }
}
```

型変換なども、ライブラリ側に任せられるので、非常に楽ですね。

実際には、以下のようなコードを書いて、Typesafe Configで設定を取り扱っています。

```scala
abstract class BaseSimulation extends Simulation {
  val properties = configFile

  def configFile: Config = {
    List(
      Try {
        // 環境変数から設定ファイルを指定できる。
        val path = System.getenv("CONFIG")
        ConfigFactory.parseFileAnySyntax(Paths.get(path).toFile)
      },
      Try {
        // カレントディレクトリにある、environment.{conf, json, yaml}が使える
        val wd = System.getProperty("user.dir");
        ConfigFactory.parseFileAnySyntax(Paths.get(wd, "environment").toFile)
      },
      // クラスパスに入っている、environment.{conf, json, yaml}が使える
      // 主に、負荷試験のデフォルト値として使っています。
      Try(ConfigFactory.parseResourcesAnySyntax("environment")),
      // 環境変数からも設定できる
      Try(ConfigFactory.systemEnvironment()),
      // システムプロパティからも設定できる
      Try(ConfigFactory.systemProperties()),
    )
      .filter(_.isSuccess)
      .foldLeft(ConfigFactory.empty()) {
        (a, b) => a.withFallback(b.get)
      }.resolve()
  }

  // このフィールドは負荷試験シナリオ固有の設定を使うときに使っています。
  // FQCNでネストした形で設定を掛けるようになっています。
  lazy val own = properties.getConfig(this.getClass.getName)
}
```

使い方のイメージとしては以下のようなイメージです。

```scala
class FooSimulation extends BaseSimulation {
  // ...省略

  val scn = scenario("シナリオ名")
    .exec(http("アクション名")
    .post("/foo")))

  setUp(scn.inject(
    rampUsersPerSec(own.getInt("from")) to own.getInt("to") // fromからtoに掛けてユーザを増やしていく形で負荷を掛ける
      during own.getDuration("duration") // durationの間
  ).protocols(httpConf))
}
```

ここで一つ問題があって、Typesafe ConfigのgetDurationはjava.time.Durationを返してきます。
しかし、Gatlingのduringは、scala.concurrent.duration.FiniteDurationを要求してきます。

そのため、先程紹介したコードの中に以下のような implicit conversionを用意して
楽に書けるようにしています。

```scala
abstract class BaseSimulation extends Simulation {

  // java.time.DurationからScalaのFiniteDurationにimplicit conversionする関数
  implicit def asFinite(d: java.time.Duration): FiniteDuration = Duration.fromNanos(d.toNanos)

  // ...省略
}
```

## まとめ

負荷試験を継続的にまわしていくためには、負荷試験のセットアップを簡単しなければいけません。
そのために、今回はインフラのセットアップや負荷試験ツールのセットアップまでの自動化を目指して
実際に使っているものをベースにリポジトリを公開しました。

少し癖のあるところもありますが、参考にしてみてもらえたら幸いです。

負荷試験をやっていきましょう。

リポジトリは[こちら](https://github.com/wreulicke/gatling-project-example)です。