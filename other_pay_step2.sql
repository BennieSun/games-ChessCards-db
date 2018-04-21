USE RYTreasureDB
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------
-- 兑换充值
CREATE PROCEDURE NET_PW_FilledExchange
	@strOperUserID    INT,					-- @OperUserID 
	@strAccounts	  NVARCHAR(31),			-- 充值用户
	@strGameID		  INT,					-- GAMEID
	@strOrdersID	  NVARCHAR(32),			--订单编号
	@strThirdOrderID  NVARCHAR(50),			--第三方订单编号
	@strShareID		  INT,					--ShareID
	@strPayAmount	  DECIMAL(18,2),		--支付金额
	@strCurrency      DECIMAL(18,2),		--豆子
	@strClientIP	  NVARCHAR(15),			--充值地址	
	@strErrorDescribe NVARCHAR(127) OUTPUT	--输出信息
WITH ENCRYPTION AS

-- 属性设置
SET NOCOUNT ON

-- 账号资料&订单信息共有
DECLARE @Accounts NVARCHAR(31)
DECLARE @GameID INT
DECLARE @UserID INT

-- 帐号资料
DECLARE @Nullity TINYINT
DECLARE @StunDown TINYINT

-- 订单信息
DECLARE @OperUserID INT
DECLARE @ShareID INT
DECLARE @OrderAmount DECIMAL(18,2)
DECLARE @DiscountScale DECIMAL(18,2)
DECLARE @IPAddress NVARCHAR(15)
DECLARE @Currency DECIMAL(18,2)
DECLARE @OrderID NVARCHAR(50)

-- 产品信息
DECLARE @ProductID NVARCHAR(100)
DECLARE @Price DECIMAL(18,2)
DECLARE @AttachCurrency DECIMAL(18,2)

-- 用户信息
DECLARE @Score BIGINT

-- 其他信息
DECLARE @Rate INT
DECLARE @PresentCurrency DECIMAL(18,2)

-- 执行逻辑
BEGIN

	IF (@strOrdersID IS NOT NULL and @strOrdersID != '')
	BEGIN
		-- 订单查询
		SELECT @OperUserID=OperUserID,@ShareID=ShareID,@UserID=UserID,@GameID=GameID,@Accounts=Accounts,
			@OrderID=OrderID,@OrderAmount=OrderAmount,@DiscountScale=DiscountScale,@Currency=Currency 
		FROM OnLineOrder WHERE OrderID=@strOrdersID

		-- 订单存在
		IF @OrderID IS NULL 
		BEGIN
			SET @strErrorDescribe=N'抱歉！充值订单不存在。'
			RETURN 1
		END

		-- 订单重复
		IF EXISTS(SELECT OrderID FROM ShareDetailInfo(NOLOCK) WHERE OrderID=@strOrdersID) 
		BEGIN
			SET @strErrorDescribe=N'此订单已发送过游戏币。'
			RETURN 0
		END
	END
	ELSE
	BEGIN
		-- 验证用户
		SELECT @UserID=UserID,@GameID=GameID,@Accounts=Accounts,@Nullity=Nullity,@StunDown=StunDown
		FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsInfo
		WHERE Accounts=@strAccounts

		IF @UserID IS NULL
		BEGIN
			SET @strErrorDescribe=N'抱歉！您要充值的用户账号不存在。'
			RETURN 1
		END

		IF @Nullity=1
		BEGIN
			SET @strErrorDescribe=N'抱歉！您要充值的用户账号暂时处于冻结状态，请联系客户服务中心了解详细情况。'
			RETURN 2
		END

		IF @StunDown<>0
		BEGIN
			SET @strErrorDescribe=N'抱歉！您要充值的用户账号使用了安全关闭功能，必须重新开通后才能继续使用。'
			RETURN 3
		END

		SET @OrderID=null
		SET @ShareID=@strShareID
		SET @Currency=@strCurrency
		SET @OrderAmount=@strPayAmount
		SET @OperUserID=@strOperUserID

		-- 订单重复
		IF EXISTS(SELECT SerialID FROM ShareDetailInfo(NOLOCK) WHERE ThirdOrderID=@strThirdOrderID) 
		BEGIN
			SET @strErrorDescribe=N'此订单已发送过游戏币。'
			RETURN 0
		END
	END
		

	-- 货币汇率
	--SELECT @Rate=StatusValue FROM RYAccountsDBLink.RYAccountsDB.dbo.SystemStatusInfo WHERE StatusName='RateCurrency'
	--IF @Rate=0 OR @Rate IS NULL
	--	SET @Rate=1

	-- 货币查询
	DECLARE @BeforeCurrency DECIMAL(18,2)
	SELECT @BeforeCurrency=Currency FROM UserCurrencyInfo WHERE UserID=@UserID
	IF @BeforeCurrency IS NULL
		SET @BeforeCurrency=0

	-- 充值货币	
	--SET @Currency = @PayAmount*@Rate
	SET @PresentCurrency=@Currency

	-- 查询APP产品信息
	SELECT @ProductID=ProductID,@Price=Price,@AttachCurrency=AttachCurrency FROM GlobalAppInfo(NOLOCK) WHERE TagID =0 AND Price=@strPayAmount
	IF @ProductID IS NULL
	BEGIN
		SET @strErrorDescribe=N'抱歉！产品信息不存在。'
		RETURN 3
	END

	-- 返利奖励
	IF @AttachCurrency<>0
	BEGIN
		IF NOT EXISTS (SELECT OrderID FROM ShareDetailInfo(NOLOCK) WHERE UserID=@UserID AND DATEDIFF(d,ApplyDate,GETDATE())=0)
		BEGIN
			SET @PresentCurrency=@Currency+@AttachCurrency
		END
	END
	
	UPDATE UserCurrencyInfo SET Currency=Currency+@PresentCurrency WHERE UserID=@UserID
	IF @@ROWCOUNT=0
	BEGIN
		INSERT UserCurrencyInfo(UserID,Currency) VALUES(@UserID,@PresentCurrency)
	END
	
	-- 产生记录
	IF @OrderID IS NULL
	BEGIN
		INSERT INTO ShareDetailInfo(
		OperUserID,ShareID,UserID,GameID,Accounts,ThirdOrderID,OrderAmount,PayAmount,
		Currency,BeforeCurrency,IPAddress)
		VALUES(
		@OperUserID,@StrShareID,@UserID,@GameID,@Accounts,@strThirdOrderID,@OrderAmount,@strPayAmount,
		@PresentCurrency,@BeforeCurrency,@strClientIP)
	END
	ELSE
	BEGIN
		INSERT INTO ShareDetailInfo(
			OperUserID,ShareID,UserID,GameID,Accounts,OrderID,ThirdOrderID,OrderAmount,DiscountScale,PayAmount,
			Currency,BeforeCurrency,IPAddress)
		VALUES(
			@OperUserID,@StrShareID,@UserID,@GameID,@Accounts,@OrderID,@strThirdOrderID,@OrderAmount,@DiscountScale,@strPayAmount,
			@PresentCurrency,@BeforeCurrency,@strClientIP)

		-- 更新订单状态
		UPDATE OnLineOrder SET OrderStatus=2,Currency=@PresentCurrency,PayAmount=@strPayAmount
		WHERE OrderID=@OrderID
	END
	

	--------------------------------------------------------------------------------
	-- 推广系统&代理系统
	DECLARE @SpreaderID INT	
	SELECT @SpreaderID=SpreaderID FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsInfo
	WHERE UserID = @UserID
	IF @SpreaderID<>0
	BEGIN
		-- 货币与金币的汇率
		DECLARE @GoldRate INT
		SELECT @GoldRate=StatusValue FROM RYAccountsDBLink.RYAccountsDB.dbo.SystemStatusInfo WHERE StatusName='RateGold'
		IF @GoldRate=0 OR @GoldRate IS NULL
			SET @GoldRate=1

		-- 代理系统
		DECLARE @AgentUserID INT
		DECLARE @AgentType INT
		DECLARE @AgentScale DECIMAL(18,3)
		DECLARE @PayScore BIGINT
		DECLARE @AgentScore BIGINT
		DECLARE @AgentDateID INT	
		SELECT @AgentUserID=UserID,@AgentType=AgentType,@AgentScale=AgentScale FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsAgent WHERE UserID=@SpreaderID AND Nullity=0
		IF @AgentUserID IS NOT NULL
		BEGIN
			IF @AgentType=1 -- 充值分成
			BEGIN
				-- 充值金币计算
				SET @PayScore=@Currency*@GoldRate
				SET @AgentScore=@PayScore*@AgentScale
				SET @AgentDateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)	
				-- 新增分成记录
				INSERT INTO RecordAgentInfo(DateID,UserID,AgentScale,TypeID,PayScore,Score,ChildrenID,CollectIP) VALUES(@AgentDateID,@AgentUserID,@AgentScale,1,@PayScore,@AgentScore,@UserID,@strClientIP)
				-- 代理日统计
				UPDATE StreamAgentPayInfo SET PayAmount=PayAmount+@strPayAmount,Currency=Currency+@Currency,PayScore=PayScore+@PayScore,LastCollectDate=GETDATE() WHERE DateID=@AgentDateID AND UserID=@AgentUserID
				IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO StreamAgentPayInfo(DateID,UserID,PayAmount,Currency,PayScore) VALUES(@AgentDateID,@AgentUserID,@strPayAmount,@Currency,@PayScore)
				END
			END
		END
		ELSE
		BEGIN
			DECLARE @SpreadRate DECIMAL(18,2)
			DECLARE @GrantScore BIGINT
			DECLARE @Note NVARCHAR(512)
			-- 推广分成
			SELECT @SpreadRate=FillGrantRate FROM GlobalSpreadInfo
			IF @SpreadRate IS NULL
			BEGIN
				SET @SpreadRate=0.1
			END
			
			SET @GrantScore = @Currency*@GoldRate*@SpreadRate
			SET @Note = N'充值'+LTRIM(STR(@strPayAmount))+'元'
			INSERT INTO RecordSpreadInfo(UserID,Score,TypeID,ChildrenID,CollectNote)
			VALUES(@SpreaderID,@GrantScore,3,@UserID,@Note)		
		END		
	END

	-- 记录日志
	DECLARE @DateID INT
	SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)

	UPDATE StreamShareInfo
	SET ShareTotals=ShareTotals+1
	WHERE DateID=@DateID AND ShareID=@ShareID

	IF @@ROWCOUNT=0
	BEGIN
		INSERT StreamShareInfo(DateID,ShareID,ShareTotals)
		VALUES (@DateID,@ShareID,1)
	END	 
	
END 
RETURN 0
GO
