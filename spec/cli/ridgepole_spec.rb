describe 'ridgepole' do
  let(:differ) { false }
  let(:conf) { "'" + JSON.dump(conn_spec) + "'" }

  context 'when help' do
    it do
      out, status = run_cli(:args => ['-h'])
      out = out.gsub(/Usage: .*\n/, '').strip_heredoc

      expect(status.success?).to be_truthy
      expect(out).to eq <<-EOS.strip_heredoc
        -c, --config CONF_OR_FILE
        -E, --env ENVIRONMENT
        -a, --apply
        -m, --merge
        -f, --file FILE
            --dry-run
            --table-options OPTIONS
            --bulk-change
            --default-int-limit LIMIT
            --pre-query QUERY
            --post-query QUERY
        -e, --export
            --split
            --split-with-dir
        -d, --diff DSL1 DSL2
            --reverse
            --with-apply
        -o, --output FILE
        -t, --tables TABLES
            --ignore-tables TABLES
            --disable-mysql-unsigned
            --log-file LOG_FILE
            --verbose
            --debug
        -v, --version
       EOS
    end
  end

  context 'when export' do
    it 'not split' do
      out, status = run_cli(:args => ['-c', conf, '-e', conf, conf])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
        # Export Schema
        Ridgepole::Client#dump
      EOS
    end

    it 'not split with outfile' do
      Tempfile.open("#{File.basename __FILE__}.#{$$}") do |f|
        out, status = run_cli(:args => ['-c', conf, '-e', '-o', f.path])

        expect(status.success?).to be_truthy
        expect(out.strip).to eq <<-EOS.strip_heredoc.strip
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
          Export Schema to `#{f.path}`
          Ridgepole::Client#dump
        EOS
      end
    end

    it 'not split with output stdout' do
      out, status = run_cli(:args => ['-c', conf, '-e', '-o', '-'])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
        # Export Schema
        Ridgepole::Client#dump
      EOS
    end

    it 'split' do
      out, status = run_cli(:args => ['-c', conf, '-e', '--split'])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
        Export Schema
        Ridgepole::Client#dump
          write `Schemafile`
      EOS
    end

    it 'split with outdir' do
      Tempfile.open("#{File.basename __FILE__}.#{$$}") do |f|
        out, status = run_cli(:args => ['-c', conf, '-e', '--split', '-o', f.path, conf, conf])

        expect(status.success?).to be_truthy
        expect(out.strip).to eq <<-EOS.strip_heredoc.strip
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
          Export Schema
          Ridgepole::Client#dump
            write `#{f.path}`
        EOS
      end
    end
  end

  context 'when apply' do
    it 'apply' do
      out, status = run_cli(:args => ['-c', conf, '-a'])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
        Apply `Schemafile`
        Ridgepole::Client#diff
        Ridgepole::Delta#migrate
        Ridgepole::Delta#differ?
        No change
      EOS
    end

    it 'dry-run' do
      out, status = run_cli(:args => ['-c', conf, '-a', '--dry-run'])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>true, :debug=>false}])
        Apply `Schemafile` (dry-run)
        Ridgepole::Client#diff
        Ridgepole::Delta#differ?
        Ridgepole::Delta#differ?
        No change
      EOS
    end

    context 'when differ true' do
      let(:differ) { true }

      it 'apply' do
        out, status = run_cli(:args => ['-c', conf, '-a'])

        expect(status.success?).to be_truthy
        expect(out.strip).to eq <<-EOS.strip_heredoc.strip
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
          Apply `Schemafile`
          Ridgepole::Client#diff
          Ridgepole::Delta#migrate
          Ridgepole::Delta#differ?
        EOS
      end

      it 'dry-run' do
        out, status = run_cli(:args => ['-c', conf, '-a', '--dry-run'])

        expect(status.success?).to be_truthy
        expect(out.strip).to eq <<-EOS.strip_heredoc.strip
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>true, :debug=>false}])
          Apply `Schemafile` (dry-run)
          Ridgepole::Client#diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#script
          create_table :table do
          end

          Ridgepole::Delta#migrate
          # create_table :table do

          # end

          Ridgepole::Delta#differ?
        EOS
      end
    end
  end

  context 'when diff' do
    it do
      out, status = run_cli(:args => ['-c', conf, '-d', conf, conf])

      expect(status.success?).to be_truthy
      expect(out.strip).to eq <<-EOS.strip_heredoc.strip
        Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
        Ridgepole::Client.diff
        Ridgepole::Delta#differ?
      EOS
    end

    context 'when differ true' do
      let(:differ) { true }

      it do
        out, status = run_cli(:args => ['-c', conf, '-d', conf, conf])

        # Exit code 1 if there is a difference
        expect(status.success?).to be_falsey

        expect(out.strip).to eq <<-EOS.strip_heredoc.strip
          Ridgepole::Client#initialize([{"adapter"=>"mysql2", "database"=>"ridgepole_test"}, {:dry_run=>false, :debug=>false}])
          Ridgepole::Client.diff
          Ridgepole::Delta#differ?
          Ridgepole::Delta#script
          create_table :table do
          end

          Ridgepole::Delta#migrate
          # create_table :table do

          # end
        EOS
      end
    end
  end
end
