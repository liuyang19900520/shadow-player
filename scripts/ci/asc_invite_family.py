import os,time,jwt,json,urllib.request,urllib.error,sys
key=open(os.environ["KEYFILE"]).read()
tok=jwt.encode({"iss":os.environ["ASC_ISSUER_ID"],"iat":int(time.time()),"exp":int(time.time())+1100,"aud":"appstoreconnect-v1"},key,algorithm="ES256",headers={"kid":os.environ["ASC_KEY_ID"],"typ":"JWT"})
B="https://api.appstoreconnect.apple.com"
EMAIL="yanqing_happy@icloud.com"; BUNDLE="com.liuyang19900520.shadowplayer"
def req(m,p,body=None):
    r=urllib.request.Request(B+p,method=m,data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization":"Bearer "+tok,"Content-Type":"application/json"})
    try:
        x=urllib.request.urlopen(r).read(); return json.loads(x) if x else {}
    except urllib.error.HTTPError as e: return {"error":e.code,"body":e.read().decode()[:800]}
g=lambda p:req("GET",p)
app=g(f"/v1/apps?filter[bundleId]={BUNDLE}")["data"][0]; APP=app["id"]; print("app",APP,app["attributes"]["name"])
# live version
live=None
for v in g(f"/v1/apps/{APP}/appStoreVersions?limit=10").get("data",[]):
    a=v["attributes"]; print("appStoreVersion",a["versionString"],a.get("appStoreState"))
    if a.get("appStoreState") in("READY_FOR_SALE","READY_FOR_DISTRIBUTION") and not live: live=a["versionString"]
print("live version:",live)
d=g(f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&include=buildBetaDetail,preReleaseVersion&limit=30")
inc={(i["type"],i["id"]):i["attributes"] for i in d.get("included",[])}
print("== BUILDS =="); rows=[]
for b in d.get("data",[]):
    a=b["attributes"];r=b["relationships"]
    v=inc.get(("preReleaseVersions",(r["preReleaseVersion"].get("data") or {}).get("id")),{}).get("version")
    bb=inc.get(("buildBetaDetails",(r["buildBetaDetail"].get("data") or {}).get("id")),{})
    rows.append((b["id"],v,a["version"],a.get("processingState"),a.get("expired"),bb.get("internalBuildState"),bb.get("externalBuildState")))
    print(f"id={b['id']} version={v} build={a['version']} uploaded={a.get('uploadedDate')} processing={a.get('processingState')} expired={a.get('expired')} usesNonExempt={a.get('usesNonExemptEncryption')} internal={bb.get('internalBuildState')} external={bb.get('externalBuildState')}")
cand=[x for x in rows if x[1]==live and x[3]=="VALID" and not x[4]] or [x for x in rows if x[3]=="VALID" and not x[4]]
cand.sort(key=lambda x:int(x[2]),reverse=True)
BUILD=cand[0]; print("CHOSEN BUILD:",BUILD)
print("== GROUPS / TESTERS ==")
groups=g(f"/v1/apps/{APP}/betaGroups?limit=50").get("data",[])
for x in groups: print("group",x["attributes"].get("name"),"internal",x["attributes"].get("isInternalGroup"),"publicLink",x["attributes"].get("publicLinkEnabled"))
for t in g(f"/v1/betaTesters?filter[apps]={APP}&limit=50").get("data",[]): print("tester",t["attributes"].get("email"),t["attributes"].get("inviteType"),t["attributes"].get("state"))
fam=[x for x in groups if x["attributes"]["name"]=="Family" and not x["attributes"].get("isInternalGroup")]
if fam: GID=fam[0]["id"]; print("Family exists",GID)
else:
    r=req("POST","/v1/betaGroups",{"data":{"type":"betaGroups","attributes":{"name":"Family","isInternalGroup":False,"publicLinkEnabled":False,"feedbackEnabled":True},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}})
    print("create group:",r if "error" in r else "ok"); GID=r["data"]["id"]
# tester
ex=g(f"/v1/betaTesters?filter[email]={EMAIL}&include=betaGroups").get("data",[])
if ex:
    TID=ex[0]["id"]; print("tester exists",TID,ex[0]["attributes"])
    print("add to group:",req("POST",f"/v1/betaGroups/{GID}/relationships/betaTesters",{"data":[{"type":"betaTesters","id":TID}]}) or "ok")
else:
    r=req("POST","/v1/betaTesters",{"data":{"type":"betaTesters","attributes":{"email":EMAIL},"relationships":{"betaGroups":{"data":[{"type":"betaGroups","id":GID}]}}}})
    print("create tester:",r if "error" in r else "ok"); TID=r.get("data",{}).get("id")
print("add build to group:",req("POST",f"/v1/betaGroups/{GID}/relationships/builds",{"data":[{"type":"builds","id":BUILD[0]}]}) or "ok")
print("== TEST INFO ==")
rd=g(f"/v1/apps/{APP}/betaAppReviewDetail"); print("reviewDetail before:",rd.get("data",{}).get("attributes",rd))
if "data" in rd:
    a=rd["data"]["attributes"]; want={"contactFirstName":"Yang","contactLastName":"Liu","contactPhone":"+81 7048134977","contactEmail":"liuyang19900520@gmail.com","demoAccountRequired":a.get("demoAccountRequired") or False}
    upd={k:v for k,v in want.items() if a.get(k) in (None,"")}
    if upd: print("patch reviewDetail:",req("PATCH",f"/v1/betaAppReviewDetails/{rd['data']['id']}",{"data":{"type":"betaAppReviewDetails","id":rd["data"]["id"],"attributes":upd}}).get("error","ok"))
locs=g(f"/v1/apps/{APP}/betaAppLocalizations").get("data",[]); have={l["attributes"]["locale"]:l for l in locs}
for l in locs: print("loc",l["attributes"])
for loc in ["en-US","ja","zh-Hans"]:
    if loc in have:
        a=have[loc]["attributes"]; upd={}
        if not a.get("description"): upd["description"]="Kage Loop 内测"
        if not a.get("feedbackEmail"): upd["feedbackEmail"]="liuyang19900520@gmail.com"
        if upd: print("patch",loc,req("PATCH",f"/v1/betaAppLocalizations/{have[loc]['id']}",{"data":{"type":"betaAppLocalizations","id":have[loc]["id"],"attributes":upd}}).get("error","ok"))
    else:
        r=req("POST","/v1/betaAppLocalizations",{"data":{"type":"betaAppLocalizations","attributes":{"locale":loc,"description":"Kage Loop 内测","feedbackEmail":"liuyang19900520@gmail.com"},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}})
        print("create loc",loc,r if "error" in r else "ok")
print("license:",g(f"/v1/apps/{APP}/betaLicenseAgreement").get("data",{}).get("attributes"))
# localization for build (what to test) optional
def ext(): return g(f"/v1/builds/{BUILD[0]}/buildBetaDetail")["data"]["attributes"]
st=ext(); print("buildBetaDetail:",st)
if st.get("externalBuildState")=="READY_FOR_BETA_SUBMISSION":
    r=req("POST","/v1/betaAppReviewSubmissions",{"data":{"type":"betaAppReviewSubmissions","relationships":{"build":{"data":{"type":"builds","id":BUILD[0]}}}}})
    print("submit beta review:",r if "error" in r else r["data"]["attributes"])
else: print("not submitting; state",st.get("externalBuildState"))
print("== FINAL ==")
print("buildBetaDetail:",ext())
print("submission:",g(f"/v1/builds/{BUILD[0]}/betaAppReviewSubmission").get("data",{}))
for t in g(f"/v1/betaGroups/{GID}/betaTesters").get("data",[]): print("Family tester",t["attributes"])
for b in g(f"/v1/betaGroups/{GID}/builds").get("data",[]): print("Family build",b["attributes"]["version"])
