import Config

if config_env() == :test do
  config :membrane_file_plugin, :file_impl, Membrane.File.CommonMock
else
  config :membrane_file_plugin, :file_impl, Membrane.File.CommonFile
end
