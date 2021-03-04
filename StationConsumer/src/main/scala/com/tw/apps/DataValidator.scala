package com.tw.apps

import com.amazon.deequ.{VerificationResult, VerificationSuite}
import com.amazon.deequ.checks.{Check, CheckLevel, CheckStatus}
import com.amazon.deequ.constraints.ConstraintStatus
import org.apache.spark.sql.{DataFrame, Dataset, SparkSession}


object DataValidator {

  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder
      .appName("StationConsumerDataValidator")
      .getOrCreate()

    val stationDataDF = spark.read.format("csv").load(dockeargs(0))
    val verificationResult = validate(stationDataDF)

    printReport(verificationResult)
  }

  private def printReport(verificationResult: VerificationResult) = {
    if (verificationResult.status == CheckStatus.Success) {
      println("The data passed the test, everything is fine!")
    } else {
      println("We found errors in the data:\n")

      val resultsForAllConstraints = verificationResult.checkResults
        .flatMap { case (_, checkResult) => checkResult.constraintResults }

      resultsForAllConstraints
        .filter {
          _.status != ConstraintStatus.Success
        }
        .foreach { result => println(s"${result.constraint}: ${result.message.get}") }
    }
  }

  def validate(dataDF: DataFrame) = {
    VerificationSuite()
      .onData(dataDF)
      .addCheck(
        Check(CheckLevel.Error, "unit testing my data")
          .isPositive("bikes_available", _ > 0)
          .isUnique("station_id")
          .isPositive("docks_available", _ > 0))
      .run()
  }
}
