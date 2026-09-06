--나츄르의 휴영
local s,id=GetID()
function s.initial_effect(c)
	--카드 발동 (필드에 표시)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	
	--①: 자신 메인 페이즈에 덱/패에서 레벨 2 이하의 "나츄르" 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--③: 이 카드가 묘지로 보내졌을 경우
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.pltg)
	e3:SetOperation(s.plop)
	c:RegisterEffect(e3)
end
s.listed_series={0x2a} -- "나츄르" 카드군 코드

-- ①번 효과: 특수 소환 가능 여부 확인
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2a) and c:IsLevelBelow(2) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- ①번 효과: 특수 소환 처리 및 맹세/내성 디메리트 적용
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 제약 1: 상대 턴 종료시까지, 자신은 몬스터를 통상 소환할 수 없다.
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		Duel.RegisterEffect(e1,tp)
		
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_MSET)
		Duel.RegisterEffect(e2,tp)
		
		-- 제약 2: 상대 턴 종료시까지, 자신 필드의 레벨 2 이하의 "나츄르" 몬스터는 상대 효과의 대상이 되지 않는다.
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e3:SetTargetRange(LOCATION_MZONE,0)
		e3:SetTarget(s.tgtg)
		e3:SetValue(aux.tgoval)
		e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		Duel.RegisterEffect(e3,tp)
	end
end

function s.tgtg(e,c)
	return c:IsSetCard(0x2a) and c:IsLevelBelow(2)
end

-- ③번 효과: 조건 필터
-- 카드 종류: "나츄르" 지속 마법 / 필드 마법 / 지속 함정
function s.plfilter1(c,tp)
	if not (c:IsSetCard(0x2a) and not c:IsCode(id) and (c:IsAbleToGrave() or c:IsSSetable() or c:IsType(TYPE_FIELD))) then return false end
	-- 지속 마법, 필드 마법, 지속 함정 검증
	local is_st = c:IsType(TYPE_CONTINUOUS) or c:IsType(TYPE_FIELD)
	if not is_st then return false end
	
	-- 같은 이름의 카드가 자신의 필드 / 묘지에 존재하지 않아야 함
	local code = c:GetCode()
	return not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,code)
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.plfilter1,tp,LOCATION_DECK,0,1,nil,tp)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATE)
	local tc=Duel.SelectMatchingCard(tp,s.plfilter1,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if not tc then return end
	
	-- 필드에 놓을 수 있는 상태인지 검증 (마함 존 및 필드 존 체크)
	local can_place = false
	if tc:IsType(TYPE_FIELD) then
		can_place = true
	else
		can_place = Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and tc:IsSSetable()
	end
	
	-- 놓는다 / 묘지로 보낸다 분기 처리
	local b1 = can_place
	local b2 = tc:IsAbleToGrave()
	
	if not (b1 or b2) then return end
	
	local op = 0
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id,2), aux.Stringid(id,3)) -- 0: 필드에 놓는다, 1: 묘지로 보낸다
	elseif b1 then
		op = 0
	else
		op = 1
	end
	
	if op==0 then
		if tc:IsType(TYPE_FIELD) then
			Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)
		else
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	else
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end