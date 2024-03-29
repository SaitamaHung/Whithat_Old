defmodule WhithatTest do
	use ExUnit.Case
	doctest Whithat
	doctest Whithat.Bvid
	doctest Whithat.Video.BiliBili

	test "Bvid Encode" do
		assert Whithat.Bvid.encode(6771_9840) == "BV1PJ411A727"
		assert Whithat.Bvid.encode(7_9551_9616) == "BV1kC4y1W71T"
	end

	test "Bvid Decode" do
		assert Whithat.Bvid.decode("BV1PJ411A727") == 6771_9840
		assert Whithat.Bvid.decode("BV1kC4y1W71T") == 7_9551_9616
	end

	test "Bilibili Get Info" do
		assert Whithat.Video.BiliBili.getInfo(926_757_974) == [
						 title: "「コしロ」[Remix] たまシいノし",
						 pages: [
							 %{
								 "cid" => 226_774_029,
								 "dimension" => %{"height" => 1080, "rotate" => 0, "width" => 1920},
								 "duration" => 207,
								 "from" => "vupload",
								 "page" => 1,
								 "part" => "たまシいノし",
								 "vid" => "",
								 "weblink" => ""
							 }
						 ]
					 ]
	end
end
