SELECT
	[DtSearchIndexPath] = [sq].[DtSearchIndexPath]
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