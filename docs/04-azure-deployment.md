# Azure deployment

## What I deployed

First an App Service plan, `asp-waypoint-arman`, on tier B1. The plan is the machine the app runs on. I picked B1 nstead of the free F1, because F1 falls asleep when nobody is using the app, and then `health-check.sh` gives up before it wakes up again.

Then the web app itself, `app-waypoint-arman`, running on that plan with Node 24.

To deploy, I zipped the repo and sent the zip file to Azure:

```bash
az webapp deploy --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" \
  --type zip --src-path artifacts/app.zip
```

Before that I set `SCM_DO_BUILD_DURING_DEPLOYMENT=true`, which tells Azure to run `npm install` once the files arrive. The app needs its packages, but `node_modules` is ignored in `.gitignore`, so it is never in the zip.

## What I saw in the log

```
2026-10-25T15:18:34.4551490Z POST /links 201
```

That is my own request showing up live while I watched the log with `az webapp log tail`. I had just created a short link, and `201` means the app created it.

The link worked. But the app saves its links in a file on the machine, `waypoint.db`, and that file is not in the zip. So the next deployment replaces the files and all the links are gone. That is why the app needs a real database that lives outside the machine.
