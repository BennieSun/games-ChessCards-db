USE RYAccountsDB
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------

-- 第三方登录
CREATE PROC GSP_MB_EfficacyOtherPlatform
	@cbPlatformID TINYINT,						-- 平台编号
	@strUserUin NVARCHAR(32),			        -- 用户Uin
	@strNickName NVARCHAR(32),					-- 用户昵称
	@strCompellation NVARCHAR(16),				-- 真实名字
	@cbGender TINYINT,							-- 用户性别
	@strClientIP NVARCHAR(15),					-- 连接地址
	@strMachineID NVARCHAR(32),					-- 机器标识
	@strMobilePhone NVARCHAR(11),				-- 手机号码
	@cbDeviceType TINYINT,						-- 注册来源	
	@strErrorDescribe NVARCHAR(127) OUTPUT		-- 输出信息
WITH ENCRYPTION AS

-- 属性设置
SET NOCOUNT ON

-- 基本信息
DECLARE @UserID INT
DECLARE @CustomID INT
DECLARE @FaceID SMALLINT
DECLARE @Accounts NVARCHAR(31)
DECLARE @NickName NVARCHAR(31)
DECLARE @PlatformID TINYINT
DECLARE @UserUin NVARCHAR(32)
DECLARE @UnderWrite NVARCHAR(63)
DECLARE @SpreaderID INT
DECLARE @PlayTimeCount INT

-- 积分变量
DECLARE @Score BIGINT
DECLARE @Insure BIGINT
DECLARE @Beans decimal(18, 2)

-- 扩展信息
DECLARE @GameID INT
DECLARE @Gender TINYINT
DECLARE @UserMedal INT
DECLARE @Experience INT
DECLARE @LoveLiness INT
DECLARE @MemberOrder SMALLINT
DECLARE @MemberOverDate DATETIME
DECLARE @MemberSwitchDate DATETIME
DECLARE @MBUserRight INT

-- 辅助变量
DECLARE @EnjoinLogon AS INT

-- 执行逻辑
BEGIN

	-- 系统暂停
	SELECT @EnjoinLogon=StatusValue FROM SystemStatusInfo(NOLOCK) WHERE StatusName=N'EnjoinLogon'
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT @strErrorDescribe=StatusString FROM SystemStatusInfo(NOLOCK) WHERE StatusName=N'EnjoinLogon'
		RETURN 2
	END

	-- 效验地址
	SELECT @EnjoinLogon=EnjoinLogon FROM ConfineAddress(NOLOCK) WHERE AddrString=@strClientIP AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SET @strErrorDescribe=N'抱歉地通知您，系统禁止了您所在的 IP 地址的登录功能，请联系客户服务中心了解详细情况！'
		RETURN 4
	END
	
	-- 效验机器
	SELECT @EnjoinLogon=EnjoinLogon FROM ConfineMachine(NOLOCK) WHERE MachineSerial=@strMachineID AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SET @strErrorDescribe=N'抱歉地通知您，系统禁止了您的机器的登录功能，请联系客户服务中心了解详细情况！'
		RETURN 7
	END

	DECLARE @DateID INT
	SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)

	-- 查询用户
	DECLARE @Nullity TINYINT
	DECLARE @StunDown TINYINT
	DECLARE @LogonPass AS NCHAR(32)
	DECLARE @InsurePass AS NCHAR(32)
	DECLARE @MoorMachine AS TINYINT
	DECLARE	@MachineSerial NCHAR(32)
	SELECT @UserID=UserID, @GameID=GameID, @Accounts=Accounts, @NickName=NickName, @PlatformID=PlatformID, @UserUin=UserUin, @UnderWrite=UnderWrite, @LogonPass=LogonPass,
		@FaceID=FaceID, @CustomID=CustomID, @Gender=Gender, @Nullity=Nullity, @StunDown=StunDown, @UserMedal=UserMedal, @Experience=Experience,	@InsurePass=InsurePass,
		@LoveLiness=LoveLiness, @MemberOrder=MemberOrder, @MemberOverDate=MemberOverDate, @MemberSwitchDate=MemberSwitchDate,
		@MoorMachine=MoorMachine, @MachineSerial=LastLogonMachine,@SpreaderID=SpreaderID,@PlayTimeCount=PlayTimeCount,@MBUserRight=UserRight
	FROM AccountsInfo(NOLOCK) WHERE UserUin=@strUserUin AND PlatformID=@cbPlatformID

    DECLARE @strTempName NVARCHAR(31)
	-- 注册用户
	IF @UserID IS NULL
	BEGIN
	
		-- 玩家账号
		SET @strTempName=@strNickName+CONVERT(nvarchar(8),REPLACE(newid(),'-',''))
				
		-- 查询昵称
		IF EXISTS (SELECT UserID FROM AccountsInfo(NOLOCK) WHERE NickName=@strTempName)
		BEGIN
			SET @strErrorDescribe=N'此昵称已被注册，请换另一昵称尝试再次注册！'
			RETURN 30
		END
		
		-- 生成账号
		DECLARE @strTemp NVARCHAR(31)
		SET @strTemp=CONVERT(NVARCHAR(31),REPLACE(NEWID(),'-','_'))
		
		-- 注册用户
		INSERT AccountsInfo (Accounts,NickName,RegAccounts,PlatformID,UserUin,LogonPass,InsurePass,Gender,FaceID,
			GameLogonTimes,LastLogonIP,LastLogonMobile,LastLogonMachine,RegisterIP,RegisterMobile,RegisterMachine,RegisterOrigin)
		VALUES (@strTemp,@strTempName,@strTemp,@cbPlatformID,@strUserUin,N'd1fd5495e7b727081497cfce780b6456',N'',@cbGender,0,
			1,@strClientIP,N'',@strMachineID,@strClientIP,N'',@strMachineID,@cbDeviceType)
		
		-- 记录日志
		UPDATE SystemStreamInfo SET GameRegisterSuccess=GameRegisterSuccess+1 WHERE DateID=@DateID
		IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, GameRegisterSuccess) VALUES (@DateID, 1)

		-- 查询用户
		SELECT @UserID=UserID, @GameID=GameID, @Accounts=Accounts, @NickName=NickName, @PlatformID=PlatformID, @UserUin=UserUin, @UnderWrite=UnderWrite, @LogonPass=LogonPass,
			@FaceID=FaceID, @CustomID=CustomID, @Gender=Gender, @Nullity=Nullity, @StunDown=StunDown, @UserMedal=UserMedal, @Experience=Experience,
			@LoveLiness=LoveLiness, @MemberOrder=MemberOrder, @MemberOverDate=MemberOverDate, @MemberSwitchDate=MemberSwitchDate,
			@MoorMachine=MoorMachine,@SpreaderID=SpreaderID,@PlayTimeCount=PlayTimeCount,@MBUserRight=UserRight
		FROM AccountsInfo(NOLOCK) WHERE UserUin=@strUserUin AND PlatformID=@cbPlatformID

		-- 分配标识
		SELECT @GameID=GameID FROM GameIdentifier(NOLOCK) WHERE UserID=@UserID
		IF @GameID IS NULL 
		BEGIN
			SET @GameID=0
			SET @strErrorDescribe=N'用户注册成功，但未成功获取游戏 ID 号码，系统稍后将给您分配！'
		END
		ELSE UPDATE AccountsInfo SET GameID=@GameID WHERE UserID=@UserID

		----------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------
		-- 注册赠送

		-- 读取变量
		DECLARE @GrantIPCount AS BIGINT
		DECLARE @GrantScoreCount AS BIGINT
		SELECT @GrantIPCount=StatusValue FROM SystemStatusInfo(NOLOCK) WHERE StatusName=N'GrantIPCount'
		SELECT @GrantScoreCount=StatusValue FROM SystemStatusInfo(NOLOCK) WHERE StatusName=N'GrantScoreCount'

		-- 赠送限制
		IF @GrantScoreCount IS NOT NULL AND @GrantScoreCount>0 AND @GrantIPCount IS NOT NULL AND @GrantIPCount>0
		BEGIN
			-- 赠送次数
			DECLARE @GrantCount AS BIGINT
			SELECT @GrantCount=GrantCount FROM SystemGrantCount(NOLOCK) WHERE DateID=@DateID AND RegisterIP=@strClientIP
		
			-- 次数判断
			IF @GrantCount IS NOT NULL AND @GrantCount>=@GrantIPCount
			BEGIN
				SET @GrantScoreCount=0
			END
		END

		-- 赠送金币
		IF @GrantScoreCount IS NOT NULL AND @GrantScoreCount>0
		BEGIN
			-- 更新记录
			UPDATE SystemGrantCount SET GrantScore=GrantScore+@GrantScoreCount, GrantCount=GrantCount+1 WHERE DateID=@DateID AND RegisterIP=@strClientIP

			-- 插入记录
			IF @@ROWCOUNT=0
			BEGIN
				INSERT SystemGrantCount (DateID, RegisterIP, RegisterMachine, GrantScore, GrantCount) VALUES (@DateID, @strClientIP, N'', @GrantScoreCount, 1)
			END
			
			-- 查询金币
			DECLARE @CurrScore BIGINT
			DECLARE @CurrInsure BIGINT
			DECLARE @CurrMedal INT
			SELECT @CurrScore=Score,@CurrInsure=InsureScore FROM RYTreasureDBLink.RYTreasureDB.dbo.GameScoreInfo  WHERE UserID=@UserID
			SELECT @CurrMedal=UserMedal FROM AccountsInfo WHERE UserID=@UserID
			
			IF @CurrScore IS NULL SET @CurrScore=0
			IF @CurrInsure IS NULL SET @CurrInsure=0
			IF @CurrMedal IS NULL SET @CurrMedal=0	
			
			-- 赠送金币
			INSERT RYTreasureDBLink.RYTreasureDB.dbo.GameScoreInfo (UserID, Score, RegisterIP, LastLogonIP) VALUES (@UserID, @GrantScoreCount, @strClientIP, @strClientIP) 
			
			-- 流水账
			INSERT INTO RYTreasureDBLink.RYTreasureDB.dbo.RecordPresentInfo(UserID,PreScore,PreInsureScore,PresentScore,TypeID,IPAddress,CollectDate)
			VALUES (@UserID,@CurrScore,@CurrInsure,@GrantScoreCount,1,@strClientIP,GETDATE())	
			
			-- 日统计
			UPDATE RYTreasureDBLink.RYTreasureDB.dbo.StreamPresentInfo SET DateID=@DateID, PresentCount=PresentCount+1,PresentScore=PresentScore+@GrantScoreCount WHERE UserID=@UserID AND TypeID=1
			IF @@ROWCOUNT=0
			BEGIN
				INSERT RYTreasureDBLink.RYTreasureDB.dbo.StreamPresentInfo(DateID,UserID,TypeID,PresentCount,PresentScore) VALUES(@DateID,@UserID,1,1,@GrantScoreCount)
			END				
		END

		-- 赠送房卡
		DECLARE @GrantRoomCardCount AS BIGINT
		SELECT @GrantRoomCardCount=StatusValue FROM SystemStatusInfo(NOLOCK) WHERE StatusName=N'GrantRoomCardCount'
		INSERT RYTreasureDBLink.RYTreasureDB.dbo.UserRoomCard (UserID, RoomCard) VALUES (@UserID, @GrantRoomCardCount) 
		-- 房卡变化记录
		--INSERT INTO RYRecordDB..RecordRoomCard(SourceUserID, SourceRoomCard, RoomCard, TargetUserID, TargetRoomCard, TradeType, TradeRemark, RoomID, ClientIP, CollectDate)
		--VALUES (@UserID, 0, @GrantRoomCardCount, 0, 0, 1, '注册赠送房卡', '', @strClientIP, GETDATE())
		----------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------

	END	
	ELSE
	BEGIN		

	    DECLARE @strRealNickName NVARCHAR(31)
	    SET @strRealNickName = SUBSTRING(@NickName,0,LEN(@NickName)-7)
		-- 修改昵称
		IF @strRealNickName<>@strNickName
		BEGIN
			-- 玩家账号
			
			SET @strTempName=@strNickName+CONVERT(NVARCHAR(8),REPLACE(newid(),'-',''))	
				
			-- 查询昵称
			IF EXISTS (SELECT UserID FROM AccountsInfo(NOLOCK) WHERE NickName=@strTempName)
			BEGIN
				SET @strErrorDescribe=N'此昵称已被使用，请换另一昵称再次尝试登录！'
				RETURN 30
			END

			-- 更新微信的昵称
			-- IF @cbPlatformID=5
			ELSE
			BEGIN
				SET @NickName=@strTempName
				UPDATE AccountsInfo SET NickName=@strTempName WHERE UserID=@UserID
			END
		END
		
		--修改性别
		IF @cbGender<>@Gender
		BEGIN
			UPDATE AccountsInfo SET Gender=@cbGender WHERE UserID=@UserID
		END
	END
	

	-- 帐号禁止
	IF @Nullity<>0
	BEGIN
		SET @strErrorDescribe=N'您的帐号暂时处于冻结状态，请联系客户服务中心了解详细情况！'
		RETURN 2
	END	

	-- 帐号关闭
	IF @StunDown<>0
	BEGIN
		SET @strErrorDescribe=N'您的帐号使用了安全关闭功能，必须重新开通后才能继续使用！'
		RETURN 2
	END	
	
	-- 固定机器
	IF @MoorMachine=1
	BEGIN
		IF @MachineSerial<>@strMachineID
		BEGIN
			SET @strErrorDescribe=N'您的帐号使用固定机器登录功能，您现所使用的机器不是所指定的机器！'
			RETURN 1
		END
	END

	-- 推广员提成
	IF @SpreaderID<>0 
	BEGIN
		DECLARE @GrantTime	INT
		DECLARE @GrantScore	BIGINT
		DECLARE @Note NVARCHAR(512)
		SET @Note = N'游戏时长达标一次性奖励'

		SELECT @GrantTime=PlayTimeCount,@GrantScore=PlayTimeGrantScore FROM RYTreasureDBLink.RYTreasureDB.dbo.GlobalSpreadInfo
		WHERE ID=1
		IF @GrantTime IS NULL OR @GrantTime=0
		BEGIN
			SET @GrantTime = 108000 -- 30小时
			SET @GrantScore = 200000
		END			
		IF @PlayTimeCount>=@GrantTime
		BEGIN
			-- 获取提成信息
			DECLARE @RecordID INT
			SELECT @RecordID=RecordID FROM RYTreasureDBLink.RYTreasureDB.dbo.RecordSpreadInfo
			WHERE UserID = @SpreaderID AND ChildrenID = @UserID AND TypeID = 2
			IF @RecordID IS NULL
			BEGIN
				INSERT INTO RYTreasureDBLink.RYTreasureDB.dbo.RecordSpreadInfo(
					UserID,Score,TypeID,ChildrenID,CollectNote)
				VALUES(@SpreaderID,@GrantScore,2,@UserID,@Note)	
			END		
		END
	END

	-- 查询金币
	SELECT @Score=Score, @Insure=InsureScore FROM RYTreasureDBLink.RYTreasureDB.dbo.GameScoreInfo WHERE UserID=@UserID
	
	-- 查询游戏豆
	SELECT @Beans=Currency FROM RYTreasureDBLink.RYTreasureDB.dbo.UserCurrencyInfo WHERE UserID=@UserID		

	-- 数据调整
	IF @Score IS NULL SET @Score=0
	IF @Insure IS NULL SET @Insure=0
	IF @Beans IS NULL SET @Beans=0

	-- 会员等级
	IF @MemberOrder<>0 AND GETDATE()>@MemberSwitchDate
	BEGIN
		DECLARE @UserRight INT	
		SET @UserRight=0
		
		-- 删除会员
		DELETE AccountsMember WHERE UserID=@UserID AND MemberOverDate<=GETDATE()

		-- 搜索会员
		SELECT @MemberOverDate=MAX(MemberOverDate), @MemberOrder=MAX(MemberOrder), @MemberSwitchDate=MIN(MemberOverDate)
			FROM AccountsMember(NOLOCK) WHERE UserID=@UserID

		-- 数据调整
		IF @MemberOrder IS NULL 
		BEGIN
			SET @MemberOrder=0
			SET @UserRight=512
		END
		IF @MemberOverDate IS NULL SET @MemberOverDate='1980-1-1'
		IF @MemberSwitchDate IS NULL SET @MemberSwitchDate='1980-1-1'

		-- 更新数据
		UPDATE AccountsInfo SET MemberOrder=@MemberOrder, MemberOverDate=@MemberOverDate, MemberSwitchDate=@MemberSwitchDate,
			UserRight=UserRight&~@UserRight WHERE UserID=@UserID
	END

	--判断玩家是否在房间中，如果在房间中不更新动态密码
	DECLARE @LockServerIDCheck INT
	SELECT @LockServerIDCheck = ServerID FROM RYTreasureDBLink.RYTreasureDB.dbo.GameScoreLocker WHERE UserID = @UserID
	IF @LockServerIDCheck IS NOT NULL
	BEGIN
		-- 更新信息
		UPDATE AccountsInfo SET GameLogonTimes=GameLogonTimes+1, LastLogonDate=GETDATE(), LastLogonIP=@strClientIP, LastLogonMachine=@strMachineID, LastLogonMobile=@strMobilePhone 
		WHERE UserID=@UserID
	END
	ELSE
	BEGIN
		-- 更新信息
		UPDATE AccountsInfo SET GameLogonTimes=GameLogonTimes+1, LastLogonDate=GETDATE(), LastLogonIP=@strClientIP,DynamicPassTime=GETDATE(),
			DynamicPass=CONVERT(nvarchar(32),REPLACE(newid(),'-','')),LastLogonMachine=@strMachineID, LastLogonMobile=@strMobilePhone 
		WHERE UserID=@UserID
	END


	-- 记录日志
	UPDATE SystemStreamInfo SET GameLogonSuccess=GameLogonSuccess+1 WHERE DateID=@DateID
	IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, GameLogonSuccess) VALUES (@DateID, 1)

	-- 动态密码
	DECLARE @szDynamicPass  nchar(32)
	SELECT @szDynamicPass=DynamicPass FROM AccountsInfo WHERE UserID=@UserID

	-- 银行标识
	DECLARE @InsureEnabled TINYINT
	SET @InsureEnabled=0
	IF @InsurePass <> '' SET @InsureEnabled=1

	-- 代理标识
	DECLARE @IsAgent TINYINT
	SET @IsAgent =0
	IF EXISTS (SELECT * FROM AccountsAgent WHERE UserID=@UserID and Nullity=0) SET @IsAgent=1
	
	-- 锁定房间ID
	DECLARE @LockServerID INT
	DECLARE @wKindID INT
	SELECT @LockServerID=ServerID, @wKindID=KindID FROM RYTreasureDBLink.RYTreasureDB.dbo.GameScoreLocker WHERE UserID=@UserID
	IF @LockServerID IS NULL SET @LockServerID=0
	IF @wKindID IS NULL SET @wKindID=0

	DECLARE @RoomCard BIGINT
	SET @RoomCard = 0
	SELECT @RoomCard=RoomCard FROM RYTreasureDBLink.RYTreasureDB.dbo.UserRoomCard WHERE UserID=@UserID

	-- 输出变量
	SELECT @UserID AS UserID, @GameID AS GameID, @Accounts AS Accounts, @NickName AS NickName,@szDynamicPass AS DynamicPass,
		@UnderWrite AS UnderWrite,@FaceID AS FaceID, @CustomID AS CustomID, @Gender AS Gender, @UserMedal AS Ingot, 
		@Experience AS Experience,@Score AS Score, @Insure AS Insure, @Beans AS Beans, @LoveLiness AS LoveLiness, @MemberOrder AS MemberOrder, 
		@MemberOverDate AS MemberOverDate,@MoorMachine AS MoorMachine, @InsureEnabled AS InsureEnabled, @PlatformID AS LogonMode,@IsAgent AS IsAgent ,@IsAgent AS IsAgent,
		@RoomCard AS RoomCard,@LockServerID AS LockServerID, @wKindID AS KindID, @MBUserRight AS UserRight
END

RETURN 0

GO
