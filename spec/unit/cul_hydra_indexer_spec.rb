require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Hydra::Indexer, type: :unit do
	describe '#extract_index_opts' do
		context 'with empty arguments' do
			let(:args) { [] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'returns defaults' do
				expect(extracted_opts).to eq(described_class::DEFAULT_INDEX_OPTS)
			end
		end
		context 'with legacy positional arguments' do
			let(:args) { [:skip_resources, :verbose_output, :softcommit] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'retains legacy positional arguments' do
				expected_opts = args.map {|arg| [arg, arg] }.to_h.merge(reraise: false)
				expect(extracted_opts).to  eq(expected_opts)
			end
		end
		context 'with an opts hash' do
			let(:args) { [{ reraise: true }] }
			let(:extracted_opts) { described_class.extract_index_opts(args) }
			it 'extracts merges into defaults' do
				expect(extracted_opts).to eq(described_class::DEFAULT_INDEX_OPTS.merge(args.first))
			end
		end
	end
end
