require 'find'
require 'gpgme'
require 'digest'
require 'pathname'
require 'fileutils'
require 'chef/knife'

module SignAndVerify
  SIGNATURE_FILE ="checksum.gpg"

  def self.get_sha_for_dir(dir, debug)
    sums = Array.new
    root = Pathname.new(dir)
    Find.find(dir) do |file|

      if ["#{dir}/.gitignore", "#{dir}/#{SignAndVerify::SIGNATURE_FILE}"].include? file then
        puts "Skipping SHA calculation for File #{file}" unless !debug
        next
      end

      if File.directory?(file) then
        puts "Skipping SHA calculation for Directory #{file}" unless !debug
        if file.eql?("#{dir}/.git") then
          puts "Not entering directory #{file}" unless !debug
          Find.prune()
        else
          next
        end
      end

      begin
        filepath = Pathname.new(file).relative_path_from(root)
        sha = Digest::SHA256.file(file).hexdigest
        sum = "#{sha} #{filepath}"
        sums << sum
        puts "Computing SHA256 for file #{file}: #{sum}" unless !debug
      rescue
        raise "Checksum failed for '#{file}', aborting" unless !debug
      end
    end
    return Digest::SHA256.hexdigest(sums.sort!.join)
  end

  class SignCookbook < Chef::Knife
    banner "knife sign cookbook COOKBOOK"

    def run
      unless name_args.size == 1
        puts "You need to specify a cookbook"
        exit 1
      end

      cookbook = name_args.first

      unless cookbook and File.directory?(cookbook)
        puts "You need to specify a root directory"
        exit 1
      end

      root = Pathname.new(cookbook)

      file_name = root + SignAndVerify::SIGNATURE_FILE

      total_sum = SignAndVerify.get_sha_for_dir(root, true)

      puts "Computed SHA: #{total_sum}"

      crypto = GPGME::Crypto.new
      begin
        signed_total_sum = crypto.sign total_sum
      rescue
        puts "GPG Signing failed!"
        exit 1
      end

      begin
        file = File.new(file_name, 'wb')
        file.puts(signed_total_sum)
      rescue
        puts "Failed to write signature to file #{file_name}"
        exit 1
      end
      puts "Signature written to file #{file_name}"
    end
  end

  class VerifyCookbook
    cache = Chef::Config[:file_cache_path] + "/"

    Chef.event_handler do
      on :synchronized_cookbook do |cookbook_name, cookbook|
        Chef::Log.info("Coobook_name: #{cookbook_name}, cookbook: #{cookbook}")

        root = Pathname.new("#{cache}cookbooks/#{cookbook_name}")

        file_name = root + SignAndVerify::SIGNATURE_FILE

        crypto = GPGME::Crypto.new

        signature = crypto.verify File.open(file_name) do |signature|
          raise "Signature of #{file_name} could not be verified" unless signature.valid?
        end

        sha = SignAndVerify.get_sha_for_dir(root, false)

        Chef::Log.info("GPG Signed SHA: #{signature}")
        Chef::Log.info("Computed SHA: #{sha}")

        if signature.equal? sha then
          raise "GPG signed SHA '#{signature}' does not match locally computed SHA '#{sha}' for #{name}"
        end
      end
    end
  end
end
