desc "Build docs and install to Xcode"
task :docs do
  system("appledoc \
        --project-name CDTIncrementalStore \
        --project-company IBM \
        --company-id com.ibm \
        --output build/docs \
        --keep-intermediate-files \
        --no-repeat-first-par \
	Classes/")
end

