
module AWSAssumeRole

    describe Profile::Basic do

        describe 'initialize' do

            it 'should create a profile object' do

                @profile = AWSAssumeRole::Profile::Basic.new(
                    'region':            'eu-west-1',
                    'access_key_id':     'AKxxxxxxxxxxxxxxxxxx',
                    'secret_access_key': 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                )

            end

        end

    end

end

