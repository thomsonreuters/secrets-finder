from dynaconf import Dynaconf, Validator

settings = Dynaconf(
    envvar_prefix="GITHUB_INVENTORY",
    load_dotenv=True,
    settings_files=["settings.toml", ".secrets.toml"],
    validate_on_update=True,
)
settings.validators.register(
    Validator("TOKEN", required=True, is_type_of=str, len_min=1),
    Validator("ORG", required=True, is_type_of=str, len_min=1),
)
