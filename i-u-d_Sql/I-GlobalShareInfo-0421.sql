USE [RYTreasureDB]
GO

INSERT INTO [dbo].[GlobalShareInfo]
           ([ShareID]
           ,[ShareName]
           ,[ShareAlias]
           ,[ShareNote]
           ,[CollectDate])
     VALUES
           (500,
           'Google��ֵ',
           'GOOGLE',
           'Google��ֵ����'
           ,GETDATE()),
		   
           (501,
           'ƻ����ֵ',
           'IOS',
           'ƻ����ֵ����'
           ,GETDATE()),

		   (502,
           '����ͨ��ֵ',
           'SWIFTPASS',
           '����ͨ��ֵ����'
           ,GETDATE())
GO

alter table [dbo].ShareDetailInfo add ThirdOrderID nvarchar(50)

go
