#!/usr/bin/env python3
# Печатает max rec_id уведомления, относящегося к Element. PWA-id и нативный Element
# ловятся всегда, обычный Chrome ловится если в тексте уведомления есть element или matrix.
import sqlite3, plistlib, os, sys
DB=os.path.expanduser("~/Library/Group Containers/group.com.apple.usernoted/db2/db")
PWA="com.google.chrome.app.mgfpgncppeabcagkfoolfbnieibhnapb"
# Нативное приложение Element, с 7 октября 2026 вместо PWA, чтобы ссылки шли в системный браузер.
NATIVE="im.riot.app"
since=int(sys.argv[1]) if len(sys.argv)>1 else 0
c=sqlite3.connect(DB)
rows=c.execute("select r.rec_id,a.identifier,r.data from record r join app a on r.app_id=a.app_id where r.rec_id>? and (a.identifier in (?,?) or a.identifier like 'com.google.chrome%') order by r.rec_id",(since,PWA,NATIVE)).fetchall()
best=since
for rid,ident,data in rows:
    hit = ident in (PWA,NATIVE)
    if not hit:
        try:
            p=plistlib.loads(data); req=p.get('req',{})
            txt=" ".join(str(req.get(k,'')) for k in ('titl','subt','body')).lower()
            hit = ('element' in txt) or ('matrix' in txt)
        except Exception: hit=False
    if hit: best=max(best,rid)
print(best)
