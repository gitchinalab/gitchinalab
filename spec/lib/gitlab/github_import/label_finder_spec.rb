# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::LabelFinder, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }
  let_it_be(:finder) { described_class.new(project) }
  let_it_be(:bug) { create(:label, project: project, name: 'Bug') }
  let_it_be(:feature) { create(:label, project: project, name: 'Feature') }

  describe '#id_for' do
    context 'with a cache in place' do
      before do
        finder.build_cache
      end

      it 'returns the ID of the given label' do
        expect(finder.id_for(feature.name)).to eq(feature.id)
      end

      it 'returns nil for an empty cache key' do
        key = finder.cache_key_for(bug.name)

        Gitlab::Cache::Import::Caching.write(key, '')

        expect(finder.id_for(bug.name)).to be_nil
      end

      it 'returns nil for a non existing label name' do
        expect(finder.id_for('kittens')).to be_nil
      end
    end

    context 'without a cache in place' do
      it 'returns nil for a label' do
        expect(finder.id_for(feature.name)).to be_nil
      end
    end
  end

  describe '#build_cache' do
    it 'builds the cache of all project labels' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write_multiple)
        .with(
          {
            "github-import/label-finder/#{project.id}/Bug" => bug.id,
            "github-import/label-finder/#{project.id}/Feature" => feature.id
          }
        )
        .and_call_original

      finder.build_cache
    end
  end

  describe '#cache_key_for' do
    it 'returns the cache key for a label name' do
      expect(finder.cache_key_for('foo'))
        .to eq("github-import/label-finder/#{project.id}/foo")
    end
  end
end
