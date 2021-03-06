# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of EhdenRaDrugUtilization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the SkeletonComparativeEffectStudy Study. The \code{createCohorts},
#' \code{synthesizePositiveControls}, \code{runAnalyses}, and \code{runDiagnostics} arguments are
#' intended to be used to run parts of the full study at a time, but none of the parts are considered
#' to be optional.
#'
#' @param connectionDetails      An object of type \code{connectionDetails} as created using the
#'                               \code{\link[DatabaseConnector]{createConnectionDetails}} function in
#'                               the DatabaseConnector package.
#' @param cdmDatabaseSchema      Schema name where your patient-level data in OMOP CDM format resides.
#'                               Note that for SQL Server, this should include both the database and
#'                               schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema   Schema name where intermediate data can be stored. You will need to
#'                               have write priviliges in this schema. Note that for SQL Server, this
#'                               should include both the database and schema name, for example
#'                               'cdm_data.dbo'.
#' @param cohortTable            The name of the table that will be created in the work database
#'                               schema. This table will hold the exposure and outcome cohorts used in
#'                               this study.
#' @param oracleTempSchema       Should be used in Oracle to specify a schema where the user has write
#'                               priviliges for storing temporary tables.
#' @param outputFolder           Name of local folder to place results; make sure to use forward
#'                               slashes (/). Do not use a folder on a network drive since this greatly
#'                               impacts performance.
#' @param databaseId             A short string for identifying the database (e.g. 'Synpuf').
#' @param databaseName           The full name of the database (e.g. 'Medicare Claims Synthetic Public
#'                               Use Files (SynPUFs)').
#' @param databaseDescription    A short description (several sentences) of the database.
#' @param createCohorts          Create the cohortTable table with the exposure and outcome cohorts?
#' @param runDiagnostics         Run and export the study diagnostics?
#' @param minCellCount           The minimum number of subjects contributing to a count before it can
#'                               be included in packaged results.
#'
#' @export
runFeasibility <- function(connectionDetails,
                           cdmDatabaseSchema,
                           cohortDatabaseSchema = cdmDatabaseSchema,
                           cohortTable = "cohort",
                           oracleTempSchema = cohortDatabaseSchema,
                           outputFolder,
                           databaseId = "Unknown",
                           databaseName = "Unknown",
                           databaseDescription = "Unknown",
                           createCohorts = TRUE,
                           runDiagnostics = TRUE,
                           minCellCount = 5) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  if (!is.null(getOption("fftempdir")) && !file.exists(getOption("fftempdir"))) {
    warning("fftempdir '", getOption("fftempdir"), "' not found. Attempting to create folder")
    dir.create(getOption("fftempdir"), recursive = TRUE)
  }

  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "feasibilityLog.txt"))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT"))

  if (createCohorts) {
    ParallelLogger::logInfo("Creating exposure and outcome cohorts")
    connection <- DatabaseConnector::connect(connectionDetails)
    createCohorts(connection = connection,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   cohortDatabaseSchema = cohortDatabaseSchema,
                   cohortTable = cohortTable,
                   oracleTempSchema = oracleTempSchema,
                   outputFolder = outputFolder)
    DatabaseConnector::disconnect(connection)
  }

  if (runDiagnostics) {
    ParallelLogger::logInfo("Running study diagnostics")
    StudyDiagnostics::runStudyDiagnostics(packageName = "EhdenRaDrugUtilization",
                                          connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = oracleTempSchema,
                                          cohortDatabaseSchema = cohortDatabaseSchema,
                                          cohortTable = cohortTable,
                                          inclusionStatisticsFolder = outputFolder,
                                          exportFolder = file.path(outputFolder,
                                                                   "feasibilityExport"),
                                          databaseId = databaseId,
                                          databaseName = databaseName,
                                          databaseDescription = databaseDescription)
  }

}
