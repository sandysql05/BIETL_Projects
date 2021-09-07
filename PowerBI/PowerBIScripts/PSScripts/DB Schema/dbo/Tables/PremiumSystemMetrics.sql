CREATE TABLE [dbo].[PremiumSystemMetrics] (
    [Tag]                                   NVARCHAR (MAX) NULL,
    [SystemMetrics.capacityObjectId]        NVARCHAR (MAX) NULL,
    [SystemMetrics.Timestamp]               NVARCHAR (MAX) NULL,
    [SystemMemoryConsumptionInGB]           NVARCHAR (MAX) NULL,
    [DatasetsMemoryConsumptionInGB]         NVARCHAR (MAX) NULL,
    [DataflowsMemoryConsumptionInGB]        NVARCHAR (MAX) NULL,
    [PaginatedReportsMemoryConsumptionInGB] NVARCHAR (MAX) NULL,
    [DatasetsCPUConsumption]                NVARCHAR (MAX) NULL,
    [DataflowsCPUConsumption]               NVARCHAR (MAX) NULL,
    [PaginatedReportsCPUConsumption]        NVARCHAR (MAX) NULL,
    [SystemCPUConsumption]                  NVARCHAR (MAX) NULL
);

