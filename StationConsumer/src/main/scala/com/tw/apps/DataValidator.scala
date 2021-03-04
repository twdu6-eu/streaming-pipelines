package com.tw.apps

import com.amazon.deequ.VerificationSuite
import com.amazon.deequ.checks.{Check, CheckLevel}
import org.apache.spark.sql.{DataFrame, Dataset}


object DataValidator {

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
