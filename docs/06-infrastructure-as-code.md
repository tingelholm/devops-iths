# Infrastructure as Code

## What the templates describe

There are two templates, and different people run them.

**`identity.bicep`** describes the identity the pipeline logs in with. I run this one myself,
once. The pipeline cannot run it, for two reasons. The identity has to exist before the
pipeline can log in at all. And the template hands out a role, which the pipeline is not
allowed to do.

**`main.bicep`** describes the plan and the web app. The pipeline runs this one, on every
push to `main`, before it deploys the app. The values it needs, like the names, come from
`dev.bicepparam`.

`main.bicep` is split into one small file per resource. A file like that cannot be read from
the outside, so the plan sends its id out with `output`, and the web app reads it. Because
the web app reads it, Bicep knows the plan has to be created first.

Both templates live in the same resource group. Azure only touches what a template actually
mentions. `main.bicep` does not mention the identity, so the pipeline never deletes its own
login.

## What the templates do not recreate

I deleted everything in the resource group, then pushed. The pipeline built the plan and the
web app back from the files. Two things did not come back.

**The identity.** It has a template, but the pipeline does not run that one, so I ran it
myself first. The new identity got a new client id, so I also had to update
`AZURE_CLIENT_ID` in GitHub. Without that the pipeline cannot log in.

**The data.** The short links were gone. A template says which resources should exist, not
what is stored inside them. Getting data back needs backups, which is module 10.
