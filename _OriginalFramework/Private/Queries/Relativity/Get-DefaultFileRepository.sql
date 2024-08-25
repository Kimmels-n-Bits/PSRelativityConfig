SELECT
	[DefaultFileRepository] = [sq].[FileShare]
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