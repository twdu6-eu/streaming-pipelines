val sparkVersion = "2.3.0"

lazy val excludeJpountz = ExclusionRule(organization = " org.lz4", name = "lz4-java")

lazy val kafka = "org.apache.kafka" %% "kafka" % "1.0.0" % "test" //excludeAll(excludeJpountz)
lazy val sparkStreamingKafka = "org.apache.spark" %% "spark-streaming-kafka-0-10" % sparkVersion //excludeAll(excludeJpountz)
lazy val sparkSqlKafka = "org.apache.spark" %% "spark-sql-kafka-0-10" % sparkVersion //excludeAll(excludeJpountz)

lazy val root = (project in file(".")).


  settings(
    inThisBuild(List(
      organization := "com.tw",
      scalaVersion := "2.11.8",
      version := "0.0.1"
    )),

    name := "tw-station-consumer",

  libraryDependencies ++= Seq(
      "org.scalatest" %% "scalatest" % "3.0.5" % "test",
      kafka,
      "org.apache.curator" % "curator-test" % "2.10.0" % "test",
      "org.apache.spark" %% "spark-core" % sparkVersion,
      "org.apache.spark" %% "spark-sql" % sparkVersion,
      "org.apache.spark" %% "spark-streaming" % sparkVersion,
      sparkSqlKafka,
      sparkStreamingKafka,
      "com.amazon.deequ" % "deequ" % "1.1.0_spark-2.3-scala-2.11"
    )
  )
