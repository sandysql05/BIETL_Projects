CREATE TABLE [dbo].[Datasets] (
    [Tag]                              NVARCHAR (MAX) NULL,
    [Id]                               NVARCHAR (MAX) NULL,
    [Name]                             NVARCHAR (MAX) NULL,
    [ConfiguredBy]                     NVARCHAR (MAX) NULL,
    [DefaultRetentionPolicy]           NVARCHAR (MAX) NULL,
    [AddRowsApiEnabled]                NVARCHAR (MAX) NULL,
    [Tables]                           NVARCHAR (MAX) NULL,
    [WebUrl]                           NVARCHAR (MAX) NULL,
    [Relationships]                    NVARCHAR (MAX) NULL,
    [Datasources]                      NVARCHAR (MAX) NULL,
    [DefaultMode]                      NVARCHAR (MAX) NULL,
    [IsRefreshable]                    NVARCHAR (MAX) NULL,
    [IsEffectiveIdentityRequired]      NVARCHAR (MAX) NULL,
    [IsEffectiveIdentityRolesRequired] NVARCHAR (MAX) NULL,
    [IsOnPremGatewayRequired]          NVARCHAR (MAX) NULL,
    [WorkspaceId]                      NVARCHAR (MAX) NULL
);

