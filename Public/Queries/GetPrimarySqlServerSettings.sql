DECLARE @Name NVARCHAR(4000)
DECLARE @DefaultFileRepository NVARCHAR(4000)
DECLARE @EDDSFileShare NVARCHAR(4000)
DECLARE @CacheLocation NVARCHAR(4000)
DECLARE @DtSearchIndexPath NVARCHAR(4000)
DECLARE @SqlInstance NVARCHAR(4000)
DECLARE @SqlPort INT
DECLARE @SqlBackupDirectory NVARCHAR(4000)
DECLARE @SqlLogDirectory NVARCHAR(4000)
DECLARE @SqlDataDirectory NVARCHAR(4000)
DECLARE @SqlFullTextDirectory NVARCHAR(4000)

SELECT
	@Name = LEFT([rs].[Name], LEN([rs].[Name]) - CHARINDEX('\', REVERSE([rs].[Name])))
	,@SqlInstance = [rs].[Name]
	,@SqlPort = 1433
FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
	ON [c].[ArtifactID] = [rs].[Type]
WHERE [c].[Name] = N'SQL - Primary'

SELECT
	@DefaultFileRepository = [sq].[FileShare]
	,@EDDSFileShare = [sq].[FileShare]
FROM
(
	SELECT
		[FileShare] = [rs].[URL]
		,[RowNumber] = ROW_NUMBER() OVER (ORDER BY [rs].[ArtifactID])
	FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
	INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
		ON [c].[ArtifactID] = [rs].[Type]
	INNER JOIN [EDDS].[EDDSDBO].[ResourceGroupFileShareServers] AS [rgfss]
		ON [rgfss].[FileShareServerArtifactID] = [rs].[ArtifactID]
	INNER JOIN [EDDS].[EDDSDBO].[ResourceGroup] AS [rg]
		ON [rg].[ArtifactID] = [rgfss].[ResourceGroupArtifactID]
	WHERE ISNULL([rs].[IsVisible], 1) = 1
	AND [c].[Name] = N'Fileshare'
) AS [sq]
WHERE [sq].[RowNumber] = 1
	
SELECT
	@CacheLocation = [sq].[CacheLocationServer]
FROM
(
	SELECT
		[CacheLocationServer] = [rs].[URL]
		,[RowNumber] = ROW_NUMBER() OVER (ORDER BY [rs].[ArtifactID])
	FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
	INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
		ON [c].[ArtifactID] = [rs].[Type]
	INNER JOIN [EDDS].[EDDSDBO].[ResourceGroupCacheLocationServers] AS [rgcls]
		ON [rgcls].[CacheLocationServerArtifactID] = [rs].[ArtifactID]
	INNER JOIN [EDDS].[EDDSDBO].[ResourceGroup] AS [rg]
		ON [rg].[ArtifactID] = [rgcls].[ResourceGroupArtifactID]
	WHERE ISNULL([rs].[IsVisible], 1) = 1
	AND [c].[Name] = N'Cache Location Server'
) AS [sq]
WHERE [sq].[RowNumber] = 1

SELECT
	@DtSearchIndexPath = [sq].[DtSearchIndexPath]
FROM
(
	SELECT
		[DtSearchIndexPath] = [c].[Name]
		,[RowNumber] = ROW_NUMBER() OVER (ORDER BY [c].[ArtifactID])
	FROM [EDDS].[EDDSDBO].[Code] AS [c]
	INNER JOIN [EDDS].[EDDSDBO].[ZCodeArtifact_8] AS [ca]
		ON [ca].[CodeArtifactID] = [c].[ArtifactID]
	INNER JOIN [EDDS].[EDDSDBO].[ResourceGroup] AS [rg]
		ON [rg].[ArtifactID] = [ca].[AssociatedArtifactID]
) AS [sq]
WHERE [sq].[RowNumber] = 1

SELECT
	@SqlBackupDirectory = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
AND [is].[Name] = N'BackupDirectory'
AND [is].[MachineName] = @Name

IF (@SqlBackupDirectory IS NULL)
BEGIN
	SELECT
		@SqlBackupDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'BackupDirectory'
	AND [is].[MachineName] = N''
END

SELECT
	@SqlLogDirectory = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
AND [is].[Name] = N'LDFDirectory'
AND [is].[MachineName] = @Name

IF (@SqlLogDirectory IS NULL)
BEGIN
	SELECT
		@SqlLogDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'LDFDirectory'
	AND [is].[MachineName] = N''
END

SELECT
	@SqlDataDirectory = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
AND [is].[Name] = N'DataDirectory'
AND [is].[MachineName] = @Name

IF (@SqlDataDirectory IS NULL)
BEGIN
	SELECT
		@SqlDataDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'DataDirectory'
	AND [is].[MachineName] = N''
END

SELECT
	@SqlFullTextDirectory = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
AND [is].[Name] = N'FTDirectory'
AND [is].[MachineName] = @Name

IF (@SqlFullTextDirectory IS NULL)
BEGIN
	SELECT
		@SqlFullTextDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'FTDirectory'
	AND [is].[MachineName] = N''
END

SELECT
	[Name] = @Name
	,[DefaultFileRepository] = @DefaultFileRepository
	,[EDDSFileShare] = @EDDSFileShare
	,[CacheLocation] = @CacheLocation
	,[DtSearchIndexPath] = @DtSearchIndexPath
	,[SqlInstance] = @SqlInstance
	,[SqlPort] = @SqlPort
	,[SqlBackupDirectory] = @SqlBackupDirectory
	,[SqlLogDirectory] = @SqlLogDirectory
	,[SqlDataDirectory] = @SqlDataDirectory
	,[SqlFullTextDirectory] = @SqlFullTextDirectory