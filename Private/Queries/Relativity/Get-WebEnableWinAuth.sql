SELECT
	[EnableWinAuth] = IIF(COUNT(*) > 0, 1, 0)
FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
	ON [c].[ArtifactID] = [rs].[Type]
WHERE [rs].[Name] = @Name
AND [c].[Name] = 'Web:AD Authentication'
