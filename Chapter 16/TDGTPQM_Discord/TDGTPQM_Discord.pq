// This file contains your Data Connector logic
[Version = "1.0.0"]
section TDGTPQM_Discord;

// OAuth Configuration Settings
client_id = Text.FromBinary(Extension.Contents("client_id"));
client_secret = Text.FromBinary(Extension.Contents("client_secret"));
redirect_uri = "http://localhost/discord/redirect";
authorize_uri = "https://discord.com/api/oauth2/authorize?";
token_uri = "https://discord.com/api/oauth2/token";

// Satic variables
api_uri = "https://discord.com/api";

// Connector window
windowWidth = 1200;
windowHeight = 1000;

[DataSource.Kind="TDGTPQM_Discord", Publish="TDGTPQM_Discord.Publish"]
shared TDGTPQM_Discord.Contents = () =>

    let
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Users", "usersFolder", TDGTPQM_Discord.UsersNavigation(), "Folder", "Folder", false},
                {"Servers", "guildsFolder", TDGTPQM_Discord.GuildsNavigation(), "Folder", "Folder", false},
                {"Membership", "membershipFolder", TDGTPQM_Discord.MemberNavigation(), "Folder", "Folder", false}
            }
        ),
        Navigation = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")        
    in
        Navigation;

shared TDGTPQM_Discord.GetMeta = () =>
    let
        objects = TDGTPQM_Discord.Contents(),
        metadata = Value.Metadata(objects)
    in
        metadata;

TDGTPQM_Discord.UsersNavigation = () as table =>
    // Navigation
    //** Users Navigation
    let
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Me", "me", TDGTPQM_Discord.GetIdentity(), "Record", "Record", true}
            }
        ),
        Navigation = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")        
    in
        Navigation;

TDGTPQM_Discord.GuildsNavigation = () as table =>
    // Navigation
    //** Guilds (Server) Navigation
    let
        objects = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Servers", "guilds", TDGTPQM_Discord.GetGuilds(), "Table", "Table", true}
            }
        ),
        
        Navigation = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")    
    in
        Navigation;

TDGTPQM_Discord.MemberNavigation = () as table =>
    // Navigation
    //** Membership Navigation
    let
        servers = Table.ExpandRecordColumn(TDGTPQM_Discord.GetGuilds(), "Column1", {"name", "id"}, {"Name", "Key"}),
        addDataColumn = Table.AddColumn(servers, "Data", each TDGTPQM_Discord.GetGuildMember([Key])),
        addItemKindColumn = Table.AddColumn(addDataColumn, "ItemKind", each "Record"),
        addItemNameColumn = Table.AddColumn(addItemKindColumn, "ItemName", each "Function"),
        addIsLeafColumn = Table.AddColumn(addItemNameColumn, "IsLeaf", each true),

        Navigation = Table.ToNavigationTable(addIsLeafColumn, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")       
 
    in
        Navigation;

// ** Identity
TDGTPQM_Discord.GetIdentity = () as table =>
    let
        apiCall = Json.Document(
            Web.Contents(
                api_uri,
                [
                    RelativePath = "users/@me"
                ]
            )
        ),
        output = Table.FromRecords({apiCall})
    in
        output;

// ** Servers (Guilds)
TDGTPQM_Discord.GetGuilds = () as table =>
    let
        apiCall = Json.Document(
            Web.Contents(
                api_uri,
                [
                    RelativePath = "users/@me/guilds"
                ]
            )
        ),
        output = Table.FromList(apiCall, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        output;


// ** Member User
TDGTPQM_Discord.GetGuildMember = (guildid as text) as table =>
    let
        apiCall = Json.Document(
            Web.Contents(
                api_uri,
                [
                    RelativePath = "users/@me/guilds/" & guildid & "/member"
                ]
            )
        ),
        output = Table.FromRecords({apiCall})
    in
        output;

// Data Source Kind description
TDGTPQM_Discord = [
    TestConnection = (dataSourcePath) => {"TDGTPQM_Discord.Contents"},
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin
        ]
    ]
];

//
// OAuth2 flow definition
//
StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = authorize_uri
            & Uri.BuildQueryString(
                [
                    client_id = client_id,
                    redirect_uri = redirect_uri,
                    response_type = "code",
                    scope = "identify email connections guilds guilds.members.read"
                ]
            )
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) => 
    let 
        Parts = Uri.Parts(callbackUri)[Query] 
    in 
        TokenMethod(Parts[code]);

TokenMethod = (code) =>
    let
        Response = Web.Contents(
            token_uri,
            [
                Content = Text.ToBinary(
                    Uri.BuildQueryString(
                        [
                            client_id = client_id,
                            client_secret = client_secret,
                            grant_type = "authorization_code",
                            code = code,
                            redirect_uri = redirect_uri
                        ]
                    )
                ),
                Headers = [#"Content-type" = "application/x-www-form-urlencoded", #"Accept" = "application/json"]
            ]
        ),
        Parts = Json.Document(Response)
    in
        Parts;

// Data Source UI publishing description
TDGTPQM_Discord.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = TDGTPQM_Discord.Icons,
    SourceTypeImage = TDGTPQM_Discord.Icons
];

TDGTPQM_Discord.Icons = [
    Icon16 = { Extension.Contents("TDGTPQM_Discord16.png"), Extension.Contents("TDGTPQM_Discord20.png"), Extension.Contents("TDGTPQM_Discord24.png"), Extension.Contents("TDGTPQM_Discord32.png") },
    Icon32 = { Extension.Contents("TDGTPQM_Discord32.png"), Extension.Contents("TDGTPQM_Discord40.png"), Extension.Contents("TDGTPQM_Discord48.png"), Extension.Contents("TDGTPQM_Discord64.png") }
];

// Navigation Tables Functions
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            Preview.DelayColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;
