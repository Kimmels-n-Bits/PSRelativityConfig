SELECT
	[CacheLocation] = [sq].[CacheLocationServer]
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