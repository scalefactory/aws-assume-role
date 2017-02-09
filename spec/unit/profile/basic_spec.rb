
module AwsAssumeRole
    describe Profile::Basic do
        describe "initialize" do
            it "creates a profile object" do
                @profile = AwsAssumeRole::Profile::Basic.new(
                    region:            "eu-west-1",
                    access_key_id:     "AKxxxxxxxxxxxxxxxxxx",
                    secret_access_key:
                        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
                )
            end
        end
    end
end
