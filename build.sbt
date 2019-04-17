enablePlugins(GatlingPlugin)
enablePlugins(PackPlugin)

name := "gatling-project-example"
cancelable in Global := true

scalaVersion := "2.12.7"

scalacOptions := Seq(
  "-encoding", "UTF-8", "-target:jvm-1.8", "-deprecation",
  "-feature", "-unchecked", "-language:implicitConversions", "-language:postfixOps")

libraryDependencies += "io.gatling.highcharts" % "gatling-charts-highcharts" % "3.0.1"
libraryDependencies += "io.gatling"            % "gatling-test-framework"    % "3.0.1"
libraryDependencies += "com.amazonaws" % "aws-java-sdk-s3" % "1.11.466"

// settings for pack
scalaSource in Compile := baseDirectory.value / "src/test/scala"
resourceDirectory in Compile := baseDirectory.value / "src/test/resources"

packMain := Map("gatling" -> "io.gatling.app.Gatling")
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
