package com.tw.apps

import com.amazon.deequ.checks.CheckStatus
import com.tw.apps.DataValidator.validate
import org.apache.spark.sql.SparkSession
import org.scalatest._


class DataValidatorTest extends FeatureSpec with Matchers with GivenWhenThen {
  feature( "Check output for data validity") {
    val spark = SparkSession.builder.appName("Test App").master("local").getOrCreate()
    spark.conf.set("spark.sql.session.timeZone", "UTC")
    import spark.implicits._


    scenario("valid record") {
      val testStationData = StationDataWithISOTimeStamp(
        19,
        41,
        is_renting = true,
        is_returning = true,
        "2021-03-03T14:07:13",
        "83",
        "Atlantic Ave & Fort Greene Pl",
        13.97632328,
        -73.97632328)


      val verificationResult = validate(Seq(testStationData).toDF())

      verificationResult.status shouldBe CheckStatus.Success
    }
  }
}
