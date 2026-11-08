# Connect Power BI and Fabric to an AI agent (Hermes / Copilot CLI)

A step-by-step guide to the connection used in this demo: one Azure CLI login that gives an AI agent
access to Microsoft Fabric workspaces and the Power BI REST API. Everything here was run and
verified on WSL with Azure CLI 2.92.0 against a Fabric-only tenant (no Azure subscription).

Written for two agents — [Hermes Agent](https://hermes-agent.nousresearch.com/docs) and the
[GitHub Copilot CLI](https://github.com/github/copilot-cli) — but the auth half is identical for any
tool that can run `az` and `curl`.

---

## 1. Why a CLI login and not a Power BI connector

Power BI Desktop can open a `.pbip` project offline, but an agent cannot publish, refresh, or read
workspace metadata that way. Both Fabric and Power BI expose REST APIs behind **Microsoft Entra
tokens**, and Azure CLI is the shortest path to those tokens:

| Audience (`--resource`) | Unlocks |
| --- | --- |
| `https://api.fabric.microsoft.com` | Fabric control plane: workspaces, lakehouses, warehouses, eventhouses, pipelines |
| `https://analysis.windows.net/powerbi/api` | Power BI REST: workspaces (`groups`), datasets, reports, refresh, XMLA |
| `https://storage.azure.com` | OneLake (DFS/Blob) file and table access |
| `https://database.windows.net` | T-SQL against Warehouse / SQL endpoints / Fabric SQL databases |

One login, four audiences, refreshed on demand by `az`.

---

## 2. Install the CLI

Windows:

```powershell
winget install Microsoft.AzureCLI
```

Ubuntu / WSL:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version --query '"azure-cli"' -o tsv    # 2.92.0 used here
```

## 3. Get your tenant ID first

A device-code login with no `--tenant` lands on the account's **home** tenant, which is often not the
tenant holding your Fabric capacity. Get the right one from the Fabric portal: the tenant ID is in
the URL and in **Workspace settings → License info**, or from Entra ID → Overview.

Keep it for the next step:

```bash
TENANT=<your-tenant-id>
```

## 4. Log in

Most Fabric users have no Azure subscription. Without `--allow-no-subscriptions`, `az login` prints
*"No subscriptions found"* and later calls misbehave — so it is not optional:

```bash
az login --allow-no-subscriptions --use-device-code --tenant "$TENANT"
```

The CLI prints something like:

```text
To sign in, use a web browser to open the page https://login.microsoft.com/device
and enter the code ABC123XYZ to authenticate.
```

Open the page, enter the code, sign in as the user who owns the Fabric capacity. On WSL, open it in
the Windows browser so you are not hunting for a tab:

```bash
cmd.exe /c start https://microsoft.com/devicelogin
```

Do **not** run plain `az login` on WSL — it tries to launch a Linux GUI browser helper that usually
does not exist. Do not loop on new codes either: `AADSTS70016: Authorization is pending` just means
you have not finished the sign-in, and re-issuing codes burns the ~15-minute window.

A successful device-code login exits `0` and prints a tenant, even with no subscription:

```json
[{ "id": "<tenant-id>", "name": "N/A(tenant level account)",
   "tenantId": "<tenant-id>", "isDefault": true,
   "user": { "name": "you@yourtenant.onmicrosoft.com", "type": "user" } }]
```

## 5. Verify before you let an agent near it

Three checks, in order. Anything less than all three is not a working connection.

```bash
# 1. who are we
az account show --query '{tenant:tenantId,user:user.name}' -o tsv

# 2. the Fabric audience actually issues a token (do not print it)
az account get-access-token --resource https://api.fabric.microsoft.com \
  --query accessToken -o tsv | wc -c

# 3. real data: list workspaces
T=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $T" \
     -H "x-ms-fabric-skill: fabric-auth" \
     "https://api.fabric.microsoft.com/v1/workspaces"
```

Expected: a tenant + user, a token length in the low thousands, and a `{"value":[…]}` list of
workspaces. Verified output from this demo:

```text
tenant: cb54d064-…   user: tauseef@…onmicrosoft.com
token len: 2258
GET /v1/workspaces -> HTTP 200, 2 workspaces, capacity region Australia East
```

Check Power BI the same way:

```bash
P=$(az account get-access-token --resource https://analysis.windows.net/powerbi/api --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $P" "https://api.powerbi.com/v1.0/myorg/groups"
```

Note `"isOnDedicatedCapacity": true` in the response — that is what tells you a workspace is backed by
Fabric capacity (F SKU) rather than Power BI Pro sharing.

---

## 6. Connect Hermes Agent

Hermes inherits the Azure CLI session: it shells out to `az` and reuses the cached token, so there is
nothing to paste into a config file and no secret to store.

1. Load the auth skill so the agent follows the same procedure this guide describes:

   ```text
   skill_view("fabric-auth")
   ```

   The Microsoft Fabric skill collection (`sqldw-cli`, `spark-cli`, `eventhouse-cli`,
   `powerbi-report-cli`, …) all assume this session already exists.

2. Ask in plain English, naming the workspace and the item:

   ```text
   List the workspaces in my Fabric tenant and tell me which one is on dedicated capacity.
   ```

   ```text
   In "Fabric Learning Workspace", create a lakehouse called crash_data and
   copy accident.csv into its Files area.
   ```

3. For Power BI work in the agent, the same session covers publishing a `.pbip` or triggering a
   refresh, because `--resource https://analysis.windows.net/powerbi/api` is served by the same login.

Every Fabric REST call the agent makes should carry the skill attribution header
`x-ms-fabric-skill: <skill-name>` — that is how the Fabric skills in this repo's workflow identify
themselves, and it costs one header.

**Token lifetime is 60–90 minutes.** Long agent runs must re-acquire (`az account get-access-token`
again) rather than cache a token in a file. Never write the token or a client secret into the repo,
an `.env` you commit, or a log.

## 7. Connect the GitHub Copilot CLI

The Copilot CLI uses the same two pieces: a GitHub login for the agent itself, and this Azure CLI
session for anything touching Fabric.

```bash
copilot
```

```text
/login                              # GitHub.com, then "Sign in with a device code"
/plugin marketplace add microsoft/skills-for-fabric
/plugin install fabric-skills@fabric-collection
/plugin install powerbi-authoring@fabric-collection
```

Those plugins ship the Fabric and Power BI authoring skills; they call `az` exactly as this guide
does, so step 4 is the only credential step you repeat.

## 8. Open the local Power BI project (no cloud needed)

The reports in this repo are `.pbip` projects — plain text, diffable, agent-editable:

```powershell
powershell -ExecutionPolicy Bypass -File .\repoint-data-path.ps1
```

Then open `NewAIreportbycopilot.pbip` in Power BI Desktop and **Refresh**. This path needs no login
at all; it is the fastest way to check what an agent changed before anything is published.

To publish to Fabric:

1. In Power BI Desktop, **File → Save as** → *Power BI project files (\*.pbip)*.
2. **Publish** to the workspace from step 5 (it must be on Fabric capacity for Fabric features).
3. The semantic model becomes a Fabric item — visible to both agents via the REST APIs above.

## 9. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `ERROR: Please run 'az login'` | no cached session, or it expired | redo step 4 |
| `AADSTS70016: Authorization is pending` | sign-in not finished inside ~15 min | run step 4 again, finish the browser part promptly |
| `No subscriptions found` | tenant has no Azure subscription | add `--allow-no-subscriptions` |
| Login works, `/v1/workspaces` returns `403` | right tenant, no Fabric capacity access | check workspace role / capacity assignment |
| `/v1/workspaces` returns `401` | token audience or expiry wrong | re-acquire with `--resource https://api.fabric.microsoft.com` |
| Workspaces list is empty but portal shows some | logged into the wrong tenant | `az login --tenant <tenantId>` |
| Power BI API returns `403` on refresh | user lacks workspace Contributor/Admin | fix the role, not the code |

Debug a token without leaking it — decode `aud`, `exp`, `tid` only:

```bash
T=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
echo "$T" | cut -d'.' -f2 | base64 -d 2>/dev/null
```

`aud` must match the audience you requested, and `tid` must be the tenant that owns the capacity.

---

## What was actually done in this demo

1. `az login --allow-no-subscriptions --use-device-code` → device code, browser sign-in, tenant-level
   account (no Azure subscription).
2. Token acquired for `https://api.fabric.microsoft.com` (2258 chars) and
   `https://analysis.windows.net/powerbi/api` (2259 chars).
3. `GET /v1/workspaces` → HTTP 200, two workspaces (`My workspace`, `Fabric Learning Workspace`),
   both on capacity `310691ff-…`, region Australia East.
4. `GET /v1.0/myorg/groups` → HTTP 200, one group, `isOnDedicatedCapacity: true`.

That is the whole connection. The report itself is still a local `.pbip` project — publish it with
step 8 when you want it in Fabric.
