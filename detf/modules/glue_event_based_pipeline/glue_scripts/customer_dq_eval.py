import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrameCollection
from awsgluedq.transforms import EvaluateDataQuality
import concurrent.futures
import re


class GroupFilter:
    def __init__(self, name, filters):
        self.name = name
        self.filters = filters


def apply_group_filter(source_DyF, group):
    return Filter.apply(frame=source_DyF, f=group.filters)


def threadedRoute(glue_ctx, source_DyF, group_filters) -> DynamicFrameCollection:
    dynamic_frames = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        future_to_filter = {
            executor.submit(apply_group_filter, source_DyF, gf): gf
            for gf in group_filters
        }
        for future in concurrent.futures.as_completed(future_to_filter):
            gf = future_to_filter[future]
            if future.exception() is not None:
                print("%r generated an exception: %s" % (gf, future.exception()))
            else:
                dynamic_frames[gf.name] = future.result()
    return DynamicFrameCollection(dynamic_frames, glue_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Default ruleset used by all target nodes with data quality enabled
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

# Script generated for node sales
sales_node1758034106809 = glueContext.create_dynamic_frame.from_options(
    format_options={
        "quoteChar": '"',
        "withHeader": True,
        "separator": ",",
        "optimizePerformance": False,
    },
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": ["s3://datalake-bkt-06012025/bronze/sales/"],
        "recurse": True,
    },
    transformation_ctx="sales_node1758034106809",
)

# Script generated for node customers
customers_node1758034094700 = glueContext.create_dynamic_frame.from_options(
    format_options={
        "quoteChar": '"',
        "withHeader": True,
        "separator": ",",
        "optimizePerformance": False,
    },
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": ["s3://datalake-bkt-06012025/bronze/customers/"],
        "recurse": True,
    },
    transformation_ctx="customers_node1758034094700",
)

# # Script generated for node customers
# customers_node1758034094700 = glueContext.create_dynamic_frame.from_options(
#     format_options={},
#     connection_type="s3",
#     format="parquet",
#     connection_options={
#         "paths": ["s3://datalake-bkt-06012025/bronze/customers/"],
#         "recurse": True,
#     },
#     transformation_ctx="customers_node1758034094700",
# )

# Script generated for node Evaluate Data Quality
EvaluateDataQuality_node1758034672435_ruleset = """
    # Example rules: Completeness "colA" between 0.4 and 0.8, ColumnCount > 10
    Rules = [
        RowCount > 45,
        IsPrimaryKey "CUSTOMERID",
        ColumnLength "CUSTOMERNAME" > 20,
        ColumnLength "EMAIL" between 18 and 26,
        # CustomSql "SELECT COUNT(*) FROM PRIMARY WHERE EMAIL IS NULL" = 0,
        ReferentialIntegrity "CUSTOMERID" "SALES.CUSTOMERID" = 1.0
    ]
"""

EvaluateDataQuality_node1758034672435_additional_sources = {
    "salesIntegrity": sales_node1758034106809
}

EvaluateDataQuality_node1758034672435 = EvaluateDataQuality().process_rows(
    frame=customers_node1758034094700,
    additional_data_sources=EvaluateDataQuality_node1758034672435_additional_sources,
    ruleset=EvaluateDataQuality_node1758034672435_ruleset,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_node1758034672435",
        "enableDataQualityCloudWatchMetrics": True,
        "enableDataQualityResultsPublishing": True,
    },
    additional_options={
        "observations.scope": "ALL",
        "performanceTuning.caching": "CACHE_NOTHING",
    },
)

###################################################################################
###################################################################################

# Script generated for node ruleOutcomes
ruleOutcomes_node1758034843609 = SelectFromCollection.apply(
    dfc=EvaluateDataQuality_node1758034672435,
    key="ruleOutcomes",
    transformation_ctx="ruleOutcomes_node1758034843609",
)

# Script generated for node customers_dqe_result
EvaluateDataQuality().process_rows(
    frame=ruleOutcomes_node1758034843609,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_node1758027425458",
        "enableDataQualityResultsPublishing": True,
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL",
    },
)
customers_dqe_result_node1758035183774 = glueContext.write_dynamic_frame.from_options(
    frame=ruleOutcomes_node1758034843609,
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": "s3://datalake-bkt-06012025/DQE-Results/customers/",
        "partitionKeys": [],
    },
    format_options={"compression": "snappy"},
    transformation_ctx="customers_dqe_result_node1758035183774",
)

###################################################################################

# Script generated for node rowLevelOutcomes
rowLevelOutcomes_node1758034827505 = SelectFromCollection.apply(
    dfc=EvaluateDataQuality_node1758034672435,
    key="rowLevelOutcomes",
    transformation_ctx="rowLevelOutcomes_node1758034827505",
)

# Script generated for node Conditional Data Flow Router
ConditionalDataFlowRouter_node1758035372790 = threadedRoute(
    glueContext,
    source_DyF=rowLevelOutcomes_node1758034827505,
    group_filters=[
        GroupFilter(
            name="failed_group",
            filters=lambda row: (
                bool(re.match("failed", row["DataQualityEvaluationResult"]))
            ),
        ),
        GroupFilter(
            name="default_group",
            filters=lambda row: (
                not (bool(re.match("failed", row["DataQualityEvaluationResult"])))
            ),
        ),
    ],
)

# Script generated for node failed_group
failed_group_node1758035373505 = SelectFromCollection.apply(
    dfc=ConditionalDataFlowRouter_node1758035372790,
    key="failed_group",
    transformation_ctx="failed_group_node1758035373505",
)

# Script generated for node default_group
default_group_node1758035373400 = SelectFromCollection.apply(
    dfc=ConditionalDataFlowRouter_node1758035372790,
    key="default_group",
    transformation_ctx="default_group_node1758035373400",
)


# Script generated for node customers_dqe_failed
EvaluateDataQuality().process_rows(
    frame=failed_group_node1758035373505,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_node1758027425458",
        "enableDataQualityResultsPublishing": True,
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL",
    },
)
customers_dqe_failed_node1758036081240 = glueContext.write_dynamic_frame.from_options(
    frame=failed_group_node1758035373505,
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": "s3://datalake-bkt-06012025/DQE-Results/customers_failed/",
        "partitionKeys": [],
    },
    format_options={"compression": "snappy"},
    transformation_ctx="customers_dqe_failed_node1758036081240",
)

# Script generated for node customer_passed
EvaluateDataQuality().process_rows(
    frame=default_group_node1758035373400,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_node1758027425458",
        "enableDataQualityResultsPublishing": True,
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL",
    },
)
customer_passed_node1758035581149 = glueContext.write_dynamic_frame.from_options(
    frame=default_group_node1758035373400,
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": "s3://datalake-bkt-06012025/gold/customers/",
        "partitionKeys": [],
    },
    format_options={"compression": "snappy"},
    transformation_ctx="customer_passed_node1758035581149",
)

job.commit()
