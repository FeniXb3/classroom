# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_member_removed.json") }
  let(:organization) { classroom_org }
  let(:student)      { create(:user, uid: payload.dig("member", "id")) }

  context "ACTION member_removed", :vcr do
    it "removes user from team" do
      group_assignment = create(:group_assignment, title: "Intro to Rails #2", organization: organization)
      group = Group.create(github_team_id: payload.dig("team", "id"), grouping: group_assignment.grouping)
      repo_access = RepoAccess.find_or_create_by!(user: student, organization: organization)

      # fails with the next line
      group.repo_accesses << repo_access

      MembershipEventJob.perform_now(payload)
      expect { group.repo_accesses.find_by(user_id: student.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end