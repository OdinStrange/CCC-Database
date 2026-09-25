--붉은 눈의 종기사
local s,id=GetID()

function s.initial_effect(c)
	---------------------------------------------------------
	-- ①: 이 카드가 패에 존재하고, 카드가 세트되거나 몬스터에 장착되었을 경우에 발동
	--	 덱/묘지의 레벨7↓ 전사족 "붉은 눈" 1장 특소
	--	 그 후 이 카드를 공격력 400 올리는 장착 마법 카드로 취급하여 장착
	---------------------------------------------------------
	-- 1) 마법 / 함정 세트 시 (EVENT_SSET)
	local e1a=Effect.CreateEffect(c)
	e1a:SetDescription(aux.Stringid(id,0))
	e1a:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1a:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1a:SetProperty(EFFECT_FLAG_DELAY)
	e1a:SetCode(EVENT_SSET)
	e1a:SetRange(LOCATION_HAND)
	e1a:SetCountLimit(1,id)
	e1a:SetTarget(s.eqtg1)
	e1a:SetOperation(s.eqop1)
	c:RegisterEffect(e1a)

	-- 2) 몬스터 세트 시 (EVENT_MSET)
	local e1b=e1a:Clone()
	e1b:SetCode(EVENT_MSET)
	c:RegisterEffect(e1b)

	-- 3) 뒷면 표시 특수 소환 시 (EVENT_SPSUMMON_SUCCESS)
	local e1c=e1a:Clone()
	e1c:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1c:SetCondition(s.spsuccesscon)
	c:RegisterEffect(e1c)

	-- 4) 표시 형식 변경으로 뒷면이 되었을 경우 (EVENT_CHANGE_POS)
	local e1d=e1a:Clone()
	e1d:SetCode(EVENT_CHANGE_POS)
	e1d:SetCondition(s.changeposcon)
	c:RegisterEffect(e1d)

	-- 5) 몬스터에 장착되었을 경우 (EVENT_EQUIP)
	local e1e=e1a:Clone()
	e1e:SetCode(EVENT_EQUIP)
	c:RegisterEffect(e1e)

	---------------------------------------------------------
	-- ②: 필드에서 묘지로 보내졌을 경우
	--	 흑룡 1장만을 소재로 덱으로 되돌리고,
	--	 "붉은 눈"을 융합소재로 하는 융합 몬스터를 융합 소환
	---------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.fuscon2)
	e2:SetTarget(s.fustg2)
	e2:SetOperation(s.fusop2)
	c:RegisterEffect(e2)
end

s.listed_series={SET_RED_EYES}
s.listed_names={CARD_REDEYES_B_DRAGON}

---------------------------------------------------------
-- ①번 효과 조건 함수 (아슈트라셴 삼천세계 구조 참조)
---------------------------------------------------------

-- 뒷면 표시 특수 소환 검증
function s.spsuccesscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsFacedown,1,nil)
end

-- 앞면 -> 뒷면 표시 변경 검증
function s.changeposconfilter(c)
	return c:IsFacedown() and c:IsPreviousPosition(POS_FACEUP)
end
function s.changeposcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.changeposconfilter,1,nil)
end

---------------------------------------------------------
-- ①번 효과 실행
---------------------------------------------------------

-- 특소할 후보: 자신의 덱 / 묘지의 레벨 7 이하 + 전사족 + "붉은 눈" 몬스터
function s.spfilter1(c,e,tp)
	return c:IsSetCard(SET_RED_EYES) and c:IsMonster()
		and c:IsRace(RACE_WARRIOR)
		and c:IsLevelBelow(7)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.eqtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter1),
				tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,c,1,tp,0)
end

function s.eqop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	-- 해소 시점에 이 카드가 패에 존재해야 정상적으로 장착 처리 수행
	if not (c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND)) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter1),
		tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if not tc then return end

	if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
		if Duel.Equip(tp,c,tc,true) then
			-- Equip Limit: tc에게만 장착 가능
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			e1:SetValue(function(e,cc) return cc==tc end)
			c:RegisterEffect(e1)

			-- 장착 몬스터 공격력 +400
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_EQUIP)
			e2:SetCode(EFFECT_UPDATE_ATTACK)
			e2:SetValue(400)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			c:RegisterEffect(e2)
		else
			-- 장착 실패 시 처리
			Duel.SendtoGrave(c,REASON_EFFECT)
		end
	end
	Duel.SpecialSummonComplete()
end

---------------------------------------------------------
-- ②번 효과 관련
---------------------------------------------------------

-- “필드에서 묘지로” 갔는지 체크
function s.fuscon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

-- 소재로 되돌릴 대상: 자신 필드 / 묘지의 "붉은 눈의 흑룡"
function s.tdfilter2(c,e,tp)
	return c:IsCode(CARD_REDEYES_B_DRAGON)
		and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
		and c:IsCanBeFusionMaterial()
		and c:IsAbleToDeck()
		and Duel.IsExistingMatchingCard(s.fusfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end

-- "붉은 눈"을 융합 소재로 하는 융합 몬스터
function s.fusfilter2(fc,e,tp,mc)
	if Duel.GetLocationCountFromEx(tp,tp,mc,fc)<=0 then return false end
	local mustg=aux.GetMustBeMaterialGroup(tp,nil,tp,fc,nil,REASON_FUSION)
	if #mustg>0 and not (#mustg==1 and mustg:IsContains(mc)) then return false end

	return fc:IsType(TYPE_FUSION)
		and fc:ListsArchetypeAsMaterial(SET_RED_EYES)
		and fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.fustg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE)
			and s.tdfilter2(chkc,e,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tdfilter2,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local g=Duel.SelectTarget(tp,s.tdfilter2,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsCanBeFusionMaterial() and not tc:IsImmuneToEffect(e)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.fusfilter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
	if not sc then return end

	if tc:IsFacedown() then Duel.ConfirmCards(1-tp,tc) end

	sc:SetMaterial(Group.FromCards(tc))
	Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT|REASON_MATERIAL|REASON_FUSION)

	Duel.BreakEffect()
	if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end