USE [RYPlatformDB]
GO

UPDATE [dbo].[GameProperty]
   SET 
      SortID = 705
 WHERE SortID = 704 and id=105
GO

UPDATE [dbo].[GameProperty]
   SET 
      SortID = 704
 WHERE SortID = 703 and id=104
GO

UPDATE [dbo].[GameProperty]
   SET 
      SortID = 703
 WHERE SortID = 702 and id=103
GO

UPDATE [dbo].[GameProperty]
   SET 
      SortID = 702
 WHERE SortID = 701 and id=102
GO

UPDATE [dbo].[GameProperty]
   SET 
      SortID = 701
 WHERE SortID = 700 and id=101
GO

----------------------------�����Ϸ���һ���Ϸ��Ʒ��-------------------------------------------
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
           ,'1��Ϸ��'
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
          ,'ϡ�б�ʯ����Ө��ˮ���������ʹ�ú󽫻��1����Ϸ��'
           ,0,700,0)
GO
-------------------------------�����Ϸ���һ���Ϸ��Ʒ���ϵ-----------------------------------------------
USE [RYPlatformDB]
GO

INSERT INTO [dbo].[GamePropertyRelat]
           ([PropertyID]
           ,[TagID]
           ,[TypeID])
     VALUES
           (106
           ,1
		   ,5)
GO