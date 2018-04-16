USE [RYPlatformDB]
GO

INSERT INTO [dbo].[GameProperty]
           ([ID]
           ,[Name]
           ,[Kind]
           ,[Cash]
           ,[Gold]
           ,[UserMedal]
           ,[LoveLiness]
           ,[UseArea]
           ,[ServiceArea]
           ,[BuyResultsGold]
           ,[SendLoveLiness]
           ,[RecvLoveLiness]
           ,[UseResultsGold]
           ,[UseResultsValidTime]
           ,[UseResultsValidTimeScoreMultiple]
           ,[UseResultsGiftPackage]
           ,[RegulationsInfo]
           ,[Recommend]
           ,[SortID]
           ,[Nullity])
     VALUES
           (106
           ,'1游戏豆'
           ,2
           ,'1.00'
           ,0
           ,0
           ,0
           ,7
           ,1
           ,10000
           ,0
           ,0
           ,0
          ,0
          ,0
          ,0
          ,'稀有宝石，其莹如水，其坚如玉，使用后将获得1万游戏币'
           ,0,700,0)
GO